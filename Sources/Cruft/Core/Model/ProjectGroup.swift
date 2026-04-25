import Foundation

/// A Finder-style rollup of findings sharing the same project root. Project
/// grouping is the default list view; users can flip to flat rule-view.
struct ProjectGroup: Sendable, Hashable, Identifiable {
    let id: String          // project path, or "__global__"
    let path: String
    let displayName: String
    let ecosystem: Ecosystem // the "primary" ecosystem — most bytes
    let findings: [Finding]

    var totalSize: Int64 {
        findings.reduce(0) { $0 + $1.reclaimBytes }
    }

    var isGlobal: Bool { id == "__global__" }
}

extension Array where Element == Finding {
    /// Group findings into project rollups. Global-cache findings land in a
    /// single synthetic group.
    func groupedByProject() -> [ProjectGroup] {
        var buckets: [String: [Finding]] = [:]
        for f in self {
            let key = f.projectPath ?? "__global__"
            buckets[key, default: []].append(f)
        }

        return buckets.map { (key, findings) -> ProjectGroup in
            if key == "__global__" {
                return ProjectGroup(
                    id: "__global__",
                    path: "Current User",
                    displayName: "Current User",
                    ecosystem: primaryEcosystem(of: findings),
                    findings: findings.sorted { ($0.size ?? 0) > ($1.size ?? 0) }
                )
            }
            let name = (key as NSString).lastPathComponent
            return ProjectGroup(
                id: key,
                path: key,
                displayName: name,
                ecosystem: primaryEcosystem(of: findings),
                findings: findings.sorted { ($0.size ?? 0) > ($1.size ?? 0) }
            )
        }.sorted { $0.totalSize > $1.totalSize }
    }
}

private func primaryEcosystem(of findings: [Finding]) -> Ecosystem {
    var bytes: [Ecosystem: Int64] = [:]
    for f in findings { bytes[f.ecosystem, default: 0] += f.size ?? 0 }
    return bytes.max { $0.value < $1.value }?.key ?? findings.first?.ecosystem ?? .node
}
