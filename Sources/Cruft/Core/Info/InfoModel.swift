import Foundation

/// Curated external link surfaced in the info panel. Kind drives the icon
/// and sort order (official > docs > blog > issue > forum > other).
struct InfoLink: Sendable, Hashable, Codable {
    enum Kind: String, Sendable, Hashable, Codable {
        case official        // vendor homepage, landing page
        case docs            // reference docs, guides (MDN, official project docs, etc.)
        case wiki            // community-authored encyclopedic reference — Wikipedia, Fandom, etc.
        case issue           // GitHub issue, bug tracker
        case stackOverflow   // SO thread
        case blog            // post, write-up
        case forum           // discourse, reddit thread
        case other
    }
    let title: String
    let url: String
    let kind: Kind
}

/// Language-level context. Shared across rules that target the same language
/// (every JS/TS rule points at the same `LanguageInfo`).
struct LanguageInfo: Sendable, Hashable {
    let key: String
    let displayName: String
    /// Short pitch — one sentence, shown under the title.
    let tagline: String
    /// Longer paragraph for the expanded view.
    let description: String
    let links: [InfoLink]
}

/// Tool-level context — a specific package manager, build system, or runtime
/// (bun, pnpm, Cargo, Vite, Bazel, …). Points back at a language via `languageKey`.
struct ToolInfo: Sendable, Hashable {
    let key: String
    let displayName: String
    let tagline: String
    let description: String
    /// If set, the panel also surfaces the parent language block.
    let languageKey: String?
    let links: [InfoLink]
}

/// Category-level context — a blurb about the whole *class* of tool a rule
/// belongs to (e.g. "what is a static site generator?"). Scoped to an
/// `Ecosystem`, not a language or a tool, so it applies across rules with
/// different `languageKey`/`toolKey` values. Shown in the info panel between
/// the tool and language sections.
struct EcosystemInfo: Sendable, Hashable {
    /// Identifies which `Ecosystem` case this entry describes.
    let ecosystem: Ecosystem
    /// Panel heading — e.g. "Static Site Generators".
    let displayName: String
    /// One-sentence pitch shown under the heading.
    let tagline: String
    /// Longer paragraph.
    let description: String
    /// Curated external links — Wikipedia, Jamstack.org, review articles.
    let links: [InfoLink]
}

/// Per-item context — "what is `node_modules`?", "why is it safe to trash?",
/// "how do I regenerate it?". Hangs off the `Rule` directly.
struct ItemInfo: Sendable, Hashable {
    /// Plain-English summary of what this directory or cache contains.
    let description: String
    /// Why removing it is safe (lockfile-gated, reproducible, etc.).
    let safetyNote: String?
    /// Command (or short instructions) to regenerate after cleaning.
    let regenCommand: String?
    /// Curated links specific to this item (release notes, docs sections).
    let links: [InfoLink]
}
