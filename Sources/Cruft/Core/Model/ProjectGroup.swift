import Foundation

/// A Finder-style rollup of findings sharing the same project root. Project
/// grouping is the default list view; users can flip to flat rule-view.
struct ProjectGroup: Sendable, Hashable, Identifiable {
    let id: String          // project path, "__global__", or "app:<segment>"
    let path: String
    let displayName: String
    let ecosystem: Ecosystem // the "primary" ecosystem — most bytes
    let findings: [Finding]
    /// When non-nil, this group represents per-bundle findings (per-app
    /// shader caches, Sparkle staging, Electron caches, …). The header
    /// renders the app icon + display name instead of a folder mark.
    let bundleSegment: String?

    var totalSize: Int64 {
        findings.reduce(0) { $0 + $1.reclaimBytes }
    }

    var isGlobal: Bool { id == "__global__" || id == "__system__" }
    var isSystem: Bool { id == "__system__" }
    var isAppBundle: Bool { bundleSegment != nil }
}

extension Array where Element == Finding {
    /// Group findings into rollups. Three group flavours produced:
    /// - **Project** — findings with a `projectPath`, keyed by that path
    /// - **App bundle** — findings whose rule is per-bundle (per-app shader
    ///   caches, Sparkle, Electron caches), keyed by the parent path
    ///   segment so all of an app's caches collapse into one header
    /// - **Current User** (`__global__`) — every other global-cache finding
    func groupedByProject() -> [ProjectGroup] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var buckets: [String: [Finding]] = [:]
        for f in self {
            let key: String
            if let project = f.projectPath {
                key = project
            } else if let bundle = f.bundleSegment {
                // Prefix to disambiguate from project paths on the off
                // chance a path equals an app segment string.
                key = "app:\(bundle)"
            } else if isUnderHome(path: f.presentationPath, home: home) {
                key = "__global__"
            } else {
                // Anything outside the user's home that isn't project- or
                // app-scoped is system-owned (Homebrew under /opt, Nix under
                // /nix, MacPorts under /opt/local, KDKs under /Library, …).
                key = "__system__"
            }
            buckets[key, default: []].append(f)
        }

        return buckets.map { (key, findings) -> ProjectGroup in
            if key == "__global__" {
                return ProjectGroup(
                    id: "__global__",
                    path: "Current User",
                    displayName: "Current User",
                    ecosystem: primaryEcosystem(of: findings),
                    findings: findings.sorted { ($0.size ?? 0) > ($1.size ?? 0) },
                    bundleSegment: nil
                )
            }
            if key == "__system__" {
                return ProjectGroup(
                    id: "__system__",
                    path: "System",
                    displayName: "System",
                    ecosystem: primaryEcosystem(of: findings),
                    findings: findings.sorted { ($0.size ?? 0) > ($1.size ?? 0) },
                    bundleSegment: nil
                )
            }
            if key.hasPrefix("app:") {
                let segment = String(key.dropFirst("app:".count))
                return ProjectGroup(
                    id: key,
                    path: segment,
                    // displayName resolved at render time via AppLookup —
                    // raw segment is the safe non-MainActor fallback for
                    // any non-UI consumer.
                    displayName: segment,
                    ecosystem: primaryEcosystem(of: findings),
                    findings: findings.sorted { ($0.size ?? 0) > ($1.size ?? 0) },
                    bundleSegment: segment
                )
            }
            let name = (key as NSString).lastPathComponent
            return ProjectGroup(
                id: key,
                path: key,
                displayName: name,
                ecosystem: primaryEcosystem(of: findings),
                findings: findings.sorted { ($0.size ?? 0) > ($1.size ?? 0) },
                bundleSegment: nil
            )
        }.sorted { $0.totalSize > $1.totalSize }
    }
}

private func primaryEcosystem(of findings: [Finding]) -> Ecosystem {
    var bytes: [Ecosystem: Int64] = [:]
    for f in findings { bytes[f.ecosystem, default: 0] += f.size ?? 0 }
    return bytes.max { $0.value < $1.value }?.key ?? findings.first?.ecosystem ?? .node
}

/// True if `path` is the user's home dir or any descendant of it. Strict
/// prefix check — `~/Library` / `~/.cargo` count, `/Library` doesn't.
private func isUnderHome(path: String, home: String) -> Bool {
    path == home || path.hasPrefix(home + "/")
}
