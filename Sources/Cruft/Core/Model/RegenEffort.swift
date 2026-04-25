import Foundation
import SwiftUI

/// How deep / costly it is to get this artifact back after trashing it.
/// Trash-reversible actions make this an "effort to restore" axis, not a
/// hard safety axis — except for `.extreme`, which genuinely cannot be
/// auto-regenerated because it holds user-generated data or references
/// that aren't pinned in a lockfile.
enum RegenEffort: Int, Sendable, Comparable, Hashable, Codable, CaseIterable {
    /// Quick to rebuild or reinstall — the cost barely registers.
    /// `__pycache__`, `.next`, `target/`, `node_modules` (with a warm cache),
    /// DerivedData.
    case low = 0

    /// Might take a while to redownload or rebuild — noticeable bandwidth
    /// or compile time. Global package caches, Pods, iOS DeviceSupport,
    /// first-time `cargo build`.
    case medium = 1

    /// Specific reinstall steps per version or item. `rustup` toolchains,
    /// `nvm` versions, Xcode Archives, pyenv Pythons.
    case high = 2

    /// No automatic path back. Either the directory holds irreplaceable
    /// user-generated data (AI chat transcripts, editor local history,
    /// workspace state) or reinstall would silently drift (a `node_modules`
    /// with no lockfile). Users should only delete deliberately, after
    /// archiving anything important.
    case extreme = 3

    static func < (lhs: RegenEffort, rhs: RegenEffort) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .low: "Low — quick to reinstall or rebuild"
        case .medium: "Medium — might take a while to redownload or rebuild"
        case .high: "High — specific reinstall steps per version or item"
        case .extreme: "Extreme — potentially irreversible"
        }
    }

    var shortLabel: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .extreme: "Extreme"
        }
    }

    /// SF Symbol used on the sidebar tier row and inline on rows that match
    /// this tier. The three reversible tiers share the gauge family
    /// (empty → half → full needle); `.extreme` breaks the pattern with a
    /// warning triangle to signal that the axis is qualitatively different.
    var icon: String {
        switch self {
        case .low: "gauge.with.dots.needle.bottom.0percent"
        case .medium: "gauge.with.dots.needle.bottom.50percent"
        case .high: "gauge.with.dots.needle.bottom.100percent"
        case .extreme: "triangle.circle"
        }
    }

    var tint: Color {
        // Constant-lightness hue sweep across the three reversible tiers,
        // shifted toward the blue half of the spectrum — blue → violet →
        // fuchsia, all at Tailwind's `500` brightness so no tier reads as
        // "dimmer" than another. `.extreme` breaks the sweep entirely
        // with system red to signal the qualitatively different axis
        // ("stop and think", not "more effort").
        switch self {
        case .low:     Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255)  // blue-500
        case .medium:  Color(red: 0x8B/255, green: 0x5C/255, blue: 0xF6/255)  // violet-500
        case .high:    Color(red: 0xD9/255, green: 0x46/255, blue: 0xEF/255)  // fuchsia-500
        case .extreme: .red
        }
    }
}
