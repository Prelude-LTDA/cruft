import Foundation

/// Simple JSON history log of every deletion. Plaintext (no encryption
/// ceremony — the user's home is already their problem). Stored in
/// `~/Library/Application Support/Cruft/history.json`.
struct HistoryEntry: Codable, Sendable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var ruleId: String
    var path: String
    var trashedTo: String?   // nil when not recovered via Trash
    var sizeBytes: Int64
    var method: Method

    enum Method: String, Codable, Sendable {
        case trash
        case cleanCommand

        var displayName: String {
            switch self {
            case .trash:        return "Trash"
            case .cleanCommand: return "Command"
            }
        }
    }
}

extension HistoryEntry {
    /// Sort key for the Method column in the History window — KeyPathComparator
    /// needs a directly Comparable, and the raw string sorts alphabetically
    /// in a way that's stable enough ("Command" < "Trash").
    var methodSortKey: String { method.displayName }
}

actor HistoryStore {
    private let url: URL
    private var cache: [HistoryEntry] = []
    private var loaded = false
    /// `presentationPath → most-recent cleanup timestamp` index. Built lazily
    /// from `cache` on first request, invalidated on every `append`. Lets the
    /// UI tag each finding with "Cleaned N ago" via O(1) lookup at scan time.
    private var pathIndex: [String: Date]?

    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Cruft", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.url = root.appendingPathComponent("history.json")
    }

    func load() -> [HistoryEntry] {
        if !loaded {
            // Decoder strategy must match `persist()` — we write ISO8601 so
            // history.json stays human-readable. A default JSONDecoder
            // expects .deferredToDate (seconds-since-2001 doubles) and
            // would silently fail the whole decode, leaving cache empty
            // across launches.
            let dec = JSONDecoder()
            dec.dateDecodingStrategy = .iso8601
            if let data = try? Data(contentsOf: url),
               let entries = try? dec.decode([HistoryEntry].self, from: data) {
                cache = entries
            }
            loaded = true
        }
        return cache
    }

    func append(_ entries: [HistoryEntry]) {
        _ = load()
        cache.append(contentsOf: entries)
        pathIndex = nil
        persist()
    }

    /// Snapshot of the most-recent cleanup date for every path ever cleaned.
    /// Returned by value — caller takes one snapshot at scan-start and
    /// enriches each finding against it without re-entering the actor.
    func lastCleanedIndex() -> [String: Date] {
        if let idx = pathIndex { return idx }
        _ = load()
        var idx: [String: Date] = [:]
        for e in cache {
            if let prev = idx[e.path], prev >= e.timestamp { continue }
            idx[e.path] = e.timestamp
        }
        pathIndex = idx
        return idx
    }

    /// Wipe every recorded entry. Backs the manual "Clear History" action.
    /// Doesn't touch the actual files on disk — those are already in Trash
    /// or were removed by a clean command. Persists the empty list so the
    /// clear survives a relaunch.
    func clear() {
        _ = load()    // ensure `loaded` is true so we don't repopulate from disk
        cache.removeAll()
        pathIndex = nil
        persist()
    }

    private func persist() {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(cache) {
            try? data.write(to: url)
        }
    }
}
