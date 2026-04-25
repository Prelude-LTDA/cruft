import AppKit
import SwiftUI

/// Caches NSImages loaded from the bundled Logos directory.
/// SVGs are loaded via `NSImage(contentsOfFile:)` which supports them natively
/// on macOS 14+.
enum LogoLoader {
    nonisolated(unsafe) private static let cache = NSCache<NSString, NSImage>()
    private static let logosDir: URL? = {
        guard let res = Bundle.main.resourcePath else { return nil }
        return URL(fileURLWithPath: res).appendingPathComponent("Logos", isDirectory: true)
    }()

    /// Tries SVG first (most brand marks), then WebP/PNG for vendors that
    /// only publish raster (e.g. LM Studio). NSImage handles all three
    /// natively on macOS 14+.
    private static let extensions = ["svg", "webp", "png"]

    static func image(named name: String) -> NSImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let dir = logosDir else { return nil }
        for ext in extensions {
            let url = dir.appendingPathComponent("\(name).\(ext)")
            if let img = NSImage(contentsOf: url) {
                img.isTemplate = false
                cache.setObject(img, forKey: name as NSString)
                return img
            }
        }
        return nil
    }

    /// True if the named asset is available on disk. Cheap (cached result).
    static func exists(_ name: String) -> Bool {
        image(named: name) != nil
    }
}

extension Finding {
    /// Resolution order for the bundled SVG:
    /// rule.iconAsset → (if rule.sfSymbol is set, STOP here) → runtime.iconAsset
    /// → ecosystem.defaultAsset. Returns nil if none — IconTile then falls back
    /// to rule.sfSymbol or ecosystem.glyph.
    ///
    /// The sfSymbol short-circuit is what makes `.sfSymbol = "iphone.gen3"`
    /// on the Simulator rules actually render the iPhone symbol rather than
    /// falling through to the ecosystem's default (Swift) logo.
    func resolvedIconAsset(rule: Rule) -> String? {
        if let a = rule.iconAsset, LogoLoader.exists(a) { return a }
        if rule.sfSymbol != nil { return nil }
        if let r = runtime, let a = r.iconAsset, LogoLoader.exists(a) { return a }
        if LogoLoader.exists(ecosystem.defaultAsset) { return ecosystem.defaultAsset }
        return nil
    }

    /// Tile background tint. Rule override > runtime tint > ecosystem tint.
    func resolvedTint(rule: Rule) -> Color {
        if let t = rule.brandTint { return t }
        if let rt = runtime?.tint { return rt }
        return ecosystem.tint
    }
}
