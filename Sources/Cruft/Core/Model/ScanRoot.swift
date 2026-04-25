import Foundation

/// A top-level directory the walker descends into. User-configurable; seeded
/// from sensible defaults on first launch.
struct ScanRoot: Sendable, Hashable, Codable, Identifiable {
    var path: String
    var isDefault: Bool = false
    var enabled: Bool = true
    var id: String { path }

    var url: URL { URL(fileURLWithPath: (path as NSString).expandingTildeInPath) }
    var exists: Bool { FileManager.default.fileExists(atPath: url.path) }

    // Back-compat for older persisted payloads that predate `enabled`.
    enum CodingKeys: String, CodingKey { case path, isDefault, enabled }
    init(path: String, isDefault: Bool = false, enabled: Bool = true) {
        self.path = path; self.isDefault = isDefault; self.enabled = enabled
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try c.decode(String.self, forKey: .path)
        isDefault = (try? c.decode(Bool.self, forKey: .isDefault)) ?? false
        enabled = (try? c.decode(Bool.self, forKey: .enabled)) ?? true
    }

    /// Seeded defaults — only those that actually exist on disk at first launch.
    /// Covers the common dev-folder naming conventions across macOS setups.
    static func defaults() -> [ScanRoot] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/Developer",         // Apple's recommended default
            "\(home)/Projects",
            "\(home)/Code",
            "\(home)/src",
            "\(home)/dev",
            "\(home)/work",
            "\(home)/workspace",
            "\(home)/repos",
            "\(home)/github",            // lowercase, cloned-by-hand
            "\(home)/GitHub",            // GitHub Desktop default
            "\(home)/Sites",             // classic macOS web-dev convention
            "\(home)/Documents/Code",
            "\(home)/Documents/Projects",
            "\(home)/Documents/Developer",
            "\(home)/Documents/GitHub",
        ]
        return candidates
            .filter { FileManager.default.fileExists(atPath: $0) }
            .map { ScanRoot(path: $0, isDefault: true, enabled: true) }
    }
}
