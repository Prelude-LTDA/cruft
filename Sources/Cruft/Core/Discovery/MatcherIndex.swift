import Foundation

/// Pre-bucketed rules for O(1) "is this dir name interesting" checks inside
/// the walker's hot path.
struct MatcherIndex: Sendable {
    /// Non-aggregate marker rules keyed by matched directory name.
    let byName: [String: [Rule]]
    /// Aggregate rules keyed by matched directory name.
    let aggregateByName: [String: [Rule]]
    /// Marker file names any rule cares about. Used to decide whether to even
    /// stat a dir's siblings.
    let allMarkerFiles: Set<String>

    static func build(from rules: [Rule]) -> MatcherIndex {
        var byName: [String: [Rule]] = [:]
        var aggByName: [String: [Rule]] = [:]
        var markers: Set<String> = []

        for r in rules {
            switch r.matcher {
            case let .marker(dirName, required, forbidden):
                byName[dirName, default: []].append(r)
                markers.formUnion(required)
                markers.formUnion(forbidden)
            case let .aggregateByName(dirName, required):
                aggByName[dirName, default: []].append(r)
                markers.formUnion(required)
            case .fixedPath, .fixedPathChildren, .fixedPathGrandchildren,
                 .fixedAbsolutePath, .fixedAbsolutePathChildren,
                 .darwinCachePath, .glob:
                break // not walker-matched
            }
        }
        return MatcherIndex(byName: byName, aggregateByName: aggByName, allMarkerFiles: markers)
    }

    var interestingDirNames: Set<String> {
        Set(byName.keys).union(aggregateByName.keys)
    }
}

extension Rule {
    /// Given a candidate's parent directory (and pre-enumerated siblings as
    /// a cheap first-level cache), decide whether this rule's marker
    /// preconditions hold. For `.marker` this now walks up the ancestor
    /// chain — a monorepo's `pnpm-lock.yaml` at the repo root should
    /// qualify a nested `apps/web/node_modules/` as reproducible, and
    /// a forbidden marker anywhere up the spine should disqualify.
    ///
    /// Walk stops at the nearest Git root (directory containing `.git`),
    /// at `$HOME`, or at filesystem root — whichever comes first — so we
    /// never cross out of a user's project or leak into unrelated siblings.
    func markersSatisfied(siblings: Set<String>, parent: URL) -> Bool {
        switch matcher {
        case let .marker(_, required, forbidden):
            return Self.walkAncestors(
                parent: parent,
                siblings: siblings,
                required: required,
                forbidden: forbidden
            )

        case let .aggregateByName(_, required):
            // Aggregates stay scoped to direct parent — they're already
            // anchored to a project root by the walker's discovery logic.
            return required.contains(where: siblings.contains)

        case .fixedPath, .fixedPathChildren, .fixedPathGrandchildren,
             .fixedAbsolutePath, .fixedAbsolutePathChildren,
             .darwinCachePath, .glob:
            return false
        }
    }

    private static func walkAncestors(
        parent: URL,
        siblings: Set<String>,
        required: [String],
        forbidden: [String]
    ) -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
            .standardizedFileURL.path
        var current: URL? = parent
        var depth = 0
        var foundRequired = false
        let maxDepth = 10   // defensive ceiling; repos rarely nest this deep

        while let u = current, depth < maxDepth {
            // Stop at filesystem / home boundary WITHOUT inspecting it —
            // stray files in $HOME shouldn't satisfy a monorepo check.
            if u.path == "/" || u.path == home { break }

            let names: Set<String>
            if depth == 0 {
                names = siblings   // caller already enumerated
            } else {
                names = Set((try? FileManager.default.contentsOfDirectory(atPath: u.path)) ?? [])
            }

            // Forbidden anywhere up the spine disqualifies immediately.
            if forbidden.contains(where: names.contains) { return false }

            if !foundRequired, required.contains(where: names.contains) {
                foundRequired = true
            }

            // Hit a Git root: this is the project boundary — scan its
            // contents (above) but don't climb past it.
            if names.contains(".git") { break }

            current = u.deletingLastPathComponent()
            depth += 1
        }

        return foundRequired
    }
}
