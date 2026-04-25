import Foundation

/// Orchestrates the three discovery sources (walker, spotlight, fixed-path),
/// dedups results (by canonical path + ancestor-prefix check), attaches
/// runtime info and project context, and emits `Finding`s with `size == nil`.
///
/// Streaming model: a single AsyncStream<Finding> fed by concurrent tasks.
final class DiscoveryCoordinator: Sendable {
    let rules: [Rule]
    let scanRoots: [URL]
    let spotlightEnabled: Bool

    init(rules: [Rule], scanRoots: [URL], spotlightEnabled: Bool) {
        self.rules = rules
        self.scanRoots = scanRoots
        self.spotlightEnabled = spotlightEnabled
    }

    func stream() -> AsyncStream<Finding> {
        AsyncStream { continuation in
            let task = Task {
                await self.run(continuation: continuation)
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(continuation: AsyncStream<Finding>.Continuation) async {
        let seen = SeenSet()

        // Fixed-path probe: synchronous, cheap, yields immediately.
        let fixed = FixedPathProbe(rules: rules).probe()
        for (rule, url) in fixed {
            if let finding = await Self.makeFinding(rule: rule, url: url, siblings: [], projectRoot: nil),
               await seen.insert(finding.canonicalPath) {
                continuation.yield(finding)
            }
        }

        await withTaskGroup(of: Void.self) { group in
            // One walker per scan root — parallel across roots.
            for root in scanRoots where FileManager.default.fileExists(atPath: root.path) {
                group.addTask {
                    let walker = BulkWalker(rules: self.rules)
                    do {
                        for try await cand in await walker.walk(root: root) {
                            if let finding = await Self.makeFinding(
                                rule: cand.rule,
                                url: cand.url,
                                siblings: cand.parentSiblings,
                                projectRoot: cand.projectRoot
                            ),
                               await seen.insert(finding.canonicalPath) {
                                continuation.yield(finding)
                            }
                        }
                    } catch is CancellationError {
                        return
                    } catch {
                        // quiet
                    }
                }
            }

            // Spotlight probe: finds candidates anywhere in $HOME. Hits inside
            // a configured root are dropped (the walker owns those); everything
            // else is emitted tagged `fromSpotlight = true` so the UI can dim.
            //
            // Buffer + sort by path-component count ascending before processing,
            // so the SeenSet's ancestor-prefix dedup drops the inner
            // `a/node_modules/b/node_modules` when the outer already exists.
            // (Spotlight returns results in index order, not path depth.)
            if spotlightEnabled {
                group.addTask {
                    let probe = await MainActor.run { SpotlightProbe(rules: self.rules) }
                    let stream = await MainActor.run { probe.stream() }
                    var urls: [URL] = []
                    for await url in stream {
                        if self.scanRoots.contains(where: { url.path.hasPrefix($0.path + "/") }) {
                            continue
                        }
                        urls.append(url)
                    }
                    urls.sort { $0.pathComponents.count < $1.pathComponents.count }

                    for url in urls {
                        let name = url.lastPathComponent
                        let parent = url.deletingLastPathComponent()
                        let siblings: Set<String> = {
                            (try? FileManager.default.contentsOfDirectory(atPath: parent.path))
                                .map(Set.init) ?? []
                        }()
                        for rule in self.rules {
                            if case .marker(let dn, _, _) = rule.matcher, dn == name,
                               rule.markersSatisfied(siblings: siblings, parent: parent) {
                                if var finding = await Self.makeFinding(
                                    rule: rule, url: url, siblings: siblings, projectRoot: parent),
                                   await seen.insert(finding.canonicalPath) {
                                    finding.fromSpotlight = true
                                    continuation.yield(finding)
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    /// Build a Finding without sizing. Sizing happens asynchronously and fills
    /// the size field later.
    static func makeFinding(
        rule: Rule,
        url: URL,
        siblings: Set<String>,
        projectRoot: URL?
    ) async -> Finding? {
        let values = try? url.resourceValues(forKeys: [
            .fileResourceIdentifierKey,
            .contentModificationDateKey,
            .isSymbolicLinkKey,
        ])

        // Compute a stable identifier: prefer (dev, inode) packed into 64 bits
        // if we can get it; otherwise hash of rule + canonical path.
        let canonical = url.resolvingSymlinksInPath().standardizedFileURL.path.lowercased()
        let devInode: UInt64 = packedDevInode(url: url)
        let id: UInt64 = devInode != 0 ? devInode : UInt64(bitPattern: Int64(hashOf(rule.id + ":" + canonical)))

        // Runtime detection for Node projects.
        var runtime: Runtime?
        if rule.id == "node.modules" {
            runtime = RuntimeDetector.forNodeModules(siblings: siblings)
        } else if rule.ecosystem == .python {
            runtime = RuntimeDetector.forPythonProject(siblings: siblings)
        }

        let projectName = projectRoot.map { $0.lastPathComponent }
        let isSuspicious: Bool = (values?.isSymbolicLink == true) &&
            DenyList.crossesVolumeBoundary(url, projectRoot: projectRoot)

        var finding = Finding(
            id: id,
            ruleId: rule.id,
            ecosystem: rule.ecosystem,
            tier: rule.tier,
            action: rule.action,
            canonicalPath: canonical,
            presentationPath: url.path,
            projectPath: projectRoot?.path,
            projectName: projectName,
            runtime: runtime,
            devInode: devInode,
            size: nil,
            modified: values?.contentModificationDate,
            suspiciousSymlink: isSuspicious,
            aggregatedCount: 1,
            aggregatedChildren: []
        )
        finding.sizeHint = rule.sizeHint
        return finding
    }
}

/// Shared-across-tasks dedup set keyed by canonical path.
actor SeenSet {
    private var set: Set<String> = []
    private var ancestors: [String] = []   // accepted paths, for prefix dedup

    func insert(_ canonical: String) -> Bool {
        if set.contains(canonical) { return false }
        // Ancestor-prefix check: drop nested node_modules inside node_modules.
        for a in ancestors where canonical.hasPrefix(a + "/") {
            return false
        }
        set.insert(canonical)
        ancestors.append(canonical)
        return true
    }
}

// MARK: - Helpers

/// Pack `(st_dev, st_ino)` into 64 bits. Returns 0 on failure.
func packedDevInode(url: URL) -> UInt64 {
    var st = stat()
    guard lstat(url.path, &st) == 0 else { return 0 }
    let dev = UInt64(UInt32(bitPattern: Int32(st.st_dev))) & 0xFFFF
    let ino = UInt64(st.st_ino) & 0xFFFF_FFFF_FFFF
    return (dev << 48) | ino
}

func hashOf(_ s: String) -> Int {
    var h: UInt64 = 1469598103934665603
    for b in s.utf8 {
        h ^= UInt64(b)
        h = h &* 1099511628211
    }
    return Int(bitPattern: UInt(h))
}
