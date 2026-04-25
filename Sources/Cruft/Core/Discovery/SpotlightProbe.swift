import Foundation

/// Project-tree accelerant. Fires a single `NSMetadataQuery` home-wide. Hits
/// that fall inside a configured scan root are discarded (the walker owns
/// those); remaining hits are surfaced as "Spotlight-found" so the UI can
/// dim them and the user can toggle the source on/off.
///
/// NSMetadataQuery is not `Sendable`, so we tuck it inside an `@unchecked`
/// box and only touch it on `@MainActor`.
final class SpotlightProbe: Sendable {
    private let interestingNames: [String]

    init(rules: [Rule]) {
        let idx = MatcherIndex.build(from: rules)
        self.interestingNames = Array(idx.interestingDirNames)
    }

    func stream() -> AsyncStream<URL> {
        let names = interestingNames
        return AsyncStream { continuation in
            guard !names.isEmpty else {
                continuation.finish()
                return
            }
            let box = QueryBox()
            Task { @MainActor in
                let namePredicates = names.map { NSPredicate(format: "kMDItemFSName ==[c] %@", $0) }
                let query = NSMetadataQuery()
                query.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: namePredicates)
                query.searchScopes = [NSMetadataQueryUserHomeScope]
                box.query = query

                let token = NotificationCenter.default.addObserver(
                    forName: .NSMetadataQueryDidFinishGathering,
                    object: query, queue: .main
                ) { _ in
                    for case let item as NSMetadataItem in query.results {
                        if let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                            continuation.yield(URL(fileURLWithPath: path))
                        }
                    }
                    query.stop()
                    continuation.finish()
                }
                box.token = token

                query.start()
            }
            continuation.onTermination = { _ in
                Task { @MainActor in box.stop() }
            }
        }
    }
}

/// Main-actor-accessed holder for the non-Sendable query and its observer.
@MainActor
private final class QueryBox: Sendable {
    nonisolated init() {}
    var query: NSMetadataQuery?
    var token: NSObjectProtocol?

    func stop() {
        query?.stop()
        query = nil
        if let t = token {
            NotificationCenter.default.removeObserver(t)
        }
        token = nil
    }
}
