import Foundation

/// Project-tree accelerant. Fires a single `NSMetadataQuery` home-wide. Hits
/// that fall inside a configured scan root are discarded (the walker owns
/// those); remaining hits are surfaced as "Spotlight-found" so the UI can
/// dim them and the user can toggle the source on/off.
///
/// NSMetadataQuery is not `Sendable`, so it lives behind a `@MainActor` box
/// and the observer pulls it out of `Notification.object` rather than
/// capturing it directly (which would warn under strict concurrency).
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
                ) { note in
                    // Read the query out of the notification rather than
                    // capturing it from the enclosing scope — the observer
                    // closure is `@Sendable` and NSMetadataQuery isn't,
                    // so a direct capture trips the SendableClosureCaptures
                    // warning. The block still runs on `.main` (queue:
                    // .main above), so touching the query here is safe.
                    guard let q = note.object as? NSMetadataQuery else { return }
                    for case let item as NSMetadataItem in q.results {
                        if let path = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                            continuation.yield(URL(fileURLWithPath: path))
                        }
                    }
                    q.stop()
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
