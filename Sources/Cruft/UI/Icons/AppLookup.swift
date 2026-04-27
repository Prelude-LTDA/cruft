import AppKit
import Foundation

/// Resolves a per-bundle path segment (`com.hnc.Discord`, `Discord`,
/// `com.hnc.Discord.helper.GPU`) into the user-facing app's display name,
/// bundle URL, and icon — used by the per-bundle grouping in the results
/// view.
///
/// Thread-safe and lazy. Resolution and the underlying NSWorkspace +
/// Bundle calls touch the filesystem; views call `resolveAsync(...)` from
/// a `.task` so that work runs off the main thread, and results are
/// cached indefinitely in process-wide `NSCache`s.
enum AppLookup {
    struct Metadata: Sendable {
        /// User-facing display name (e.g. "Discord", "Visual Studio Code").
        let displayName: String
        /// Canonical bundle identifier when we resolved one.
        let bundleID: String?
        /// The located `.app` bundle URL, if any. nil when the segment
        /// didn't match any installed app.
        let appURL: URL?
    }

    struct Resolved: Sendable {
        let metadata: Metadata
        let icon: NSImage?
    }

    /// Async, thread-safe entry point. Call from `.task { ... }` in the view
    /// — the actual resolve runs off the main thread; the result hops back.
    /// Cache hits return effectively instantly without ever leaving main.
    static func resolveAsync(segment: String) async -> Resolved {
        if let hit = cachedResolved(for: segment) { return hit }
        return await Task.detached(priority: .userInitiated) {
            resolveBlocking(segment: segment)
        }.value
    }

    /// Returns a cached `Resolved` if we've already done the work for this
    /// segment, otherwise nil. Used by the view to render synchronously
    /// when warm without paying a Task hop.
    static func cachedResolved(for segment: String) -> Resolved? {
        guard let metaBox = metadataCache.object(forKey: segment as NSString) else {
            return nil
        }
        let icon: NSImage? = metaBox.metadata.appURL.flatMap {
            iconCache.object(forKey: $0.path as NSString)
        }
        return Resolved(metadata: metaBox.metadata, icon: icon)
    }

    // MARK: - Internals

    /// Boxed for NSCache (which only stores reference types).
    private final class MetadataBox: @unchecked Sendable {
        let metadata: Metadata
        init(_ m: Metadata) { self.metadata = m }
    }

    nonisolated(unsafe) private static let metadataCache: NSCache<NSString, MetadataBox> = {
        let c = NSCache<NSString, MetadataBox>()
        c.countLimit = 4096
        return c
    }()

    nonisolated(unsafe) private static let iconCache: NSCache<NSString, NSImage> = {
        let c = NSCache<NSString, NSImage>()
        c.countLimit = 4096
        return c
    }()

    /// Synchronous, blocking resolve. Safe to call from any thread —
    /// NSWorkspace lookups, Bundle Info.plist reads, and FileManager
    /// existence checks are all thread-safe. Internal — public callers
    /// should use `resolveAsync(segment:)` so the work always lands off
    /// the main thread on cache miss.
    private static func resolveBlocking(segment: String) -> Resolved {
        let key = segment as NSString
        if let cached = cachedResolved(for: segment) { return cached }

        let metadata = resolveMetadata(for: segment)
        metadataCache.setObject(MetadataBox(metadata), forKey: key)

        guard let url = metadata.appURL else {
            return Resolved(metadata: metadata, icon: nil)
        }
        let iconKey = url.path as NSString
        if let cached = iconCache.object(forKey: iconKey) {
            return Resolved(metadata: metadata, icon: cached)
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        iconCache.setObject(icon, forKey: iconKey)
        return Resolved(metadata: metadata, icon: icon)
    }

    private static func resolveMetadata(for segment: String) -> Metadata {
        if let url = appURL(for: segment) {
            let bundle = Bundle(url: url)
            let displayName = bundle?.localizedInfoDictionary?["CFBundleDisplayName"] as? String
                ?? bundle?.infoDictionary?["CFBundleDisplayName"] as? String
                ?? bundle?.infoDictionary?["CFBundleName"] as? String
                ?? FileManager.default.displayName(atPath: url.path)
            return Metadata(
                displayName: displayName,
                bundleID: bundle?.bundleIdentifier,
                appURL: url
            )
        }
        // Last resort: render the raw segment string. Better than dropping
        // the row entirely — the user can still recognize many bundle IDs
        // visually (e.g. `com.example.MyApp`).
        return Metadata(displayName: segment, bundleID: nil, appURL: nil)
    }

    private static func appURL(for segment: String) -> URL? {
        // 1. Treat segment as a bundle ID, with helper-suffix walking so
        //    `com.hnc.Discord.helper.GPU` finds Discord.app.
        for candidate in canonicalBundleCandidates(for: segment) {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: candidate) {
                return url
            }
        }
        // 2. Treat segment as a display name. Probe the standard app dirs.
        let standardDirs = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            (NSHomeDirectory() as NSString).appendingPathComponent("Applications"),
        ]
        for dir in standardDirs {
            let candidate = "\(dir)/\(segment).app"
            if FileManager.default.fileExists(atPath: candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }
        return nil
    }

    /// `com.hnc.Discord.helper.GPU` → [com.hnc.Discord.helper.GPU,
    /// com.hnc.Discord.helper, com.hnc.Discord]. Handles common Electron /
    /// Chromium / Apple helper-process naming patterns. Returns `[]` if the
    /// input doesn't look like a bundle ID at all (no dot).
    private static func canonicalBundleCandidates(for segment: String) -> [String] {
        guard segment.contains(".") else { return [] }
        var out = [segment]
        let helperPatterns: [String] = [
            "helper", "Helper", "helper.GPU", "helper.gpu", "helper.Renderer",
            "helper.renderer", "helper.Plugin", "GPU", "Renderer", "Plugin",
            "(GPU)", "(Renderer)", "(Plugin)",
        ]
        var current = segment
        for _ in 0..<3 {  // safety bound — never strip more than 3 layers
            var stripped = false
            for pattern in helperPatterns {
                let suffix = ".\(pattern)"
                if current.hasSuffix(suffix) {
                    current = String(current.dropLast(suffix.count))
                    out.append(current)
                    stripped = true
                    break
                }
            }
            if !stripped { break }
        }
        return out
    }
}
