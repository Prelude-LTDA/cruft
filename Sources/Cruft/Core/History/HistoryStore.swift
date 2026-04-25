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
    }
}

actor HistoryStore {
    private let url: URL
    private var cache: [HistoryEntry] = []
    private var loaded = false

    init() {
        let root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Cruft", isDirectory: true)
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        self.url = root.appendingPathComponent("history.json")
    }

    func load() -> [HistoryEntry] {
        if !loaded {
            if let data = try? Data(contentsOf: url),
               let entries = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
                cache = entries
            }
            loaded = true
        }
        return cache
    }

    func append(_ entries: [HistoryEntry]) {
        _ = load()
        cache.append(contentsOf: entries)
        persist()
    }

    func undoable() -> [HistoryEntry] {
        // The most recent session's trash-method entries whose trashedTo still
        // exists. Caller is expected to filter further if they want per-item.
        _ = load()
        return cache.filter { $0.method == .trash && $0.trashedTo != nil }
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
