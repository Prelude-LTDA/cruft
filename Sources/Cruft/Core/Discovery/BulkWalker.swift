import Foundation

/// Depth-first parallel-across-roots recursive walker. Enumerates directories
/// one level at a time so we have the full sibling list in hand when a match
/// appears — no second stat pass. On a match, we **prune** (don't recurse into
/// the matched directory, so we never walk the 200k files inside a
/// `node_modules`).
struct WalkerCandidate: Sendable {
    let rule: Rule
    let url: URL
    let parentSiblings: Set<String>
    let projectRoot: URL?
}

actor BulkWalker {
    private let index: MatcherIndex
    private let rules: [Rule]
    private let skipDirNames: Set<String>
    private var emittedProjectsForAgg: [String: Set<String>] = [:]

    /// Hard-skip these at any depth — reduces noise and protects us from
    /// recursing into caches/VCS trees.
    private static let defaultSkip: Set<String> = [
        ".git", ".hg", ".svn", "node_modules", ".next", ".nuxt",
        ".svelte-kit", ".astro", ".turbo", ".parcel-cache", ".vite",
        "target", ".build", "DerivedData", ".gradle", "build",
        "__pycache__", ".venv", "venv", "Pods",
        ".fseventsd", ".Trashes", ".Spotlight-V100",
    ]

    /// Skip media-library bundles. These are opaque "packages" that macOS
    /// treats specially — descending into them trips the Media & Apple
    /// Music / Photos TCC gate, prompting the user every launch even though
    /// there's no dev cache inside any of them. Matched by directory
    /// extension so a renamed library still gets caught.
    private static let tccProtectedLibraryExtensions: Set<String> = [
        "musiclibrary",   // Apple Music
        "photoslibrary",  // Photos
        "tvlibrary",      // Apple TV
        "imovielibrary",  // iMovie
        "fcpbundle",      // Final Cut Pro project bundle
        "aplibrary",      // Aperture (deprecated, may linger)
    ]

    init(rules: [Rule]) {
        self.rules = rules
        self.index = MatcherIndex.build(from: rules)
        self.skipDirNames = Self.defaultSkip
    }

    /// Walk a single scan root. Yields raw candidates (matchers satisfied, but
    /// not yet deduped or sized). Honors cancellation via `Task.checkCancellation`.
    func walk(root: URL) -> AsyncThrowingStream<WalkerCandidate, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await self.recurse(
                        url: root,
                        projectRoot: nil,
                        depth: 0,
                        continuation: continuation
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func recurse(
        url: URL,
        projectRoot: URL?,
        depth: Int,
        continuation: AsyncThrowingStream<WalkerCandidate, Error>.Continuation
    ) async throws {
        try Task.checkCancellation()
        // Cap depth to avoid runaway walks; 12 levels is far deeper than any
        // real project layout.
        if depth > 12 { return }

        let children: [URL]
        do {
            children = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .volumeIdentifierKey],
                options: []
            )
        } catch {
            return // permission denied, etc. — silently skip.
        }

        // Build the sibling name set once.
        var fileNames: Set<String> = []
        var dirs: [URL] = []
        for child in children {
            let vals = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if vals?.isDirectory == true && vals?.isSymbolicLink != true {
                dirs.append(child)
            } else {
                fileNames.insert(child.lastPathComponent)
            }
        }

        // Does this directory look like a project anchor? If it contains any
        // marker file, we'll treat it (or rather, its relevant child matches)
        // as rooted here.
        let anchorIsProject = !fileNames.isDisjoint(with: index.allMarkerFiles)
        let effectiveProjectRoot = anchorIsProject ? url : projectRoot

        // Load optional .cruftignore.
        let ignore = anchorIsProject
            ? IgnoreParser.loadIfPresent(in: url)
            : .empty

        // Visit children: match rules, emit, decide whether to recurse.
        for child in dirs {
            let name = child.lastPathComponent

            // Check for direct rule matches against this child's name.
            var handled = false

            if let hits = index.byName[name] {
                for rule in hits where rule.markersSatisfied(siblings: fileNames, parent: url) {
                    if ignore.matches(path: child.path, ruleId: rule.id, relativeTo: url.path) {
                        continue
                    }
                    if !DenyList.isAllowed(child.path) { continue }
                    if DenyList.crossesVolumeBoundary(child, projectRoot: effectiveProjectRoot) {
                        continue
                    }
                    continuation.yield(WalkerCandidate(
                        rule: rule,
                        url: child,
                        parentSiblings: fileNames,
                        projectRoot: effectiveProjectRoot
                    ))
                    handled = true
                    // Only the first matching rule per dir fires; tie-broken by
                    // catalog order.
                    break
                }
            }

            // Aggregate rules: emit one per (project, rule) combo.
            if let aggHits = index.aggregateByName[name] {
                for rule in aggHits where rule.markersSatisfied(siblings: fileNames, parent: url) {
                    guard let anchor = effectiveProjectRoot else { continue }
                    let key = "\(rule.id)::\(anchor.path)"
                    if emittedProjectsForAgg[key] == nil {
                        emittedProjectsForAgg[key] = [child.path]
                        continuation.yield(WalkerCandidate(
                            rule: rule,
                            url: child,
                            parentSiblings: fileNames,
                            projectRoot: anchor
                        ))
                    } else {
                        // Subsequent hits merged into the same aggregate later.
                        emittedProjectsForAgg[key]?.insert(child.path)
                    }
                    handled = true
                    break
                }
            }

            // Prune descent: once matched, don't walk into the dir; likewise
            // skip default-skip names and media-library bundles whose
            // extension would trip a TCC gate.
            if handled || skipDirNames.contains(name) {
                continue
            }
            let ext = (name as NSString).pathExtension
            if !ext.isEmpty && Self.tccProtectedLibraryExtensions.contains(ext) {
                continue
            }

            // Avoid recursing through symlinks to sidestep loops.
            if (try? child.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true {
                continue
            }

            try await recurse(
                url: child,
                projectRoot: effectiveProjectRoot,
                depth: depth + 1,
                continuation: continuation
            )
        }
    }

    /// After the walk completes, return the aggregated children per (rule,project)
    /// so the post-processor can attach them to the aggregate Finding.
    func aggregatedChildren() -> [String: Set<String>] {
        emittedProjectsForAgg
    }
}
