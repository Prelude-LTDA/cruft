import Foundation
import SwiftUI

/// One matcher variant. Invariant enforced by the type: a bare directory-name
/// match is NOT expressible. Every directory-name rule MUST carry at least one
/// required marker, which defuses the whole class of false positives where a
/// user has a `build/` or `target/` that isn't a build artifact.
enum Matcher: Sendable, Hashable {
    /// Match a directory name scoped to a project root, requiring sibling markers.
    /// `forbiddenMarkers` lets us disambiguate Rust `target/` vs Maven `target/`.
    case marker(directoryName: String,
                requiredMarkers: [String],
                forbiddenMarkers: [String] = [])

    /// Fixed absolute path (resolved against `$HOME`). Used for global caches.
    case fixedPath(relativeToHome: String)

    /// Like `.fixedPath` but emits one finding per direct child directory.
    /// Used for version-manager installs (`~/.rustup/toolchains`,
    /// `~/.nvm/versions/node`, `~/.pyenv/versions`) so each version is
    /// individually sizable and deletable.
    case fixedPathChildren(relativeToHome: String)

    /// Like `.fixedPathChildren` but enumerates TWO levels deep.
    /// Used for hierarchies like `~/.lmstudio/models/<publisher>/<model>`
    /// where the first level is a grouping (publisher / org) and the second
    /// is the actual deletable unit.
    case fixedPathGrandchildren(relativeToHome: String)

    /// Fully-qualified absolute path (no `$HOME` prefix). Used for paths
    /// owned by root like `/nix/store` or `/opt/local/var/macports/*`.
    /// These typically pair with `.shellSudo` actions since we can't
    /// `NSWorkspace.recycle` them directly.
    case fixedAbsolutePath(String)

    /// Like `.fixedAbsolutePath` but emits one finding per direct child.
    /// Used for `/Library/Developer/KDKs/*.kdk` or
    /// `/Library/Developer/CoreSimulator/Profiles/Runtimes/*.simruntime` so
    /// individual items are sizable and deletable.
    case fixedAbsolutePathChildren(String)

    /// Path inside `$DARWIN_USER_CACHE_DIR` (the dynamic per-user cache
    /// at `/private/var/folders/<X>/<Y>/C/`). Resolves the prefix at probe
    /// time via `confstr(_CS_DARWIN_USER_CACHE_DIR)`. Used for top-level
    /// shader caches (e.g. `com.apple.metal/`) that catch non-bundled
    /// binaries — `cargo run`, `swift run`, ad-hoc Python scripts.
    case darwinCachePath(relativePath: String)

    /// Per-bundle subdirectory inside `$DARWIN_USER_CACHE_DIR/<bundle-id>/`.
    /// Probes every first-level child of the Darwin cache root, checks for
    /// the named subdirectory, and emits one finding per bundle whose cache
    /// contains it. Used for things like per-app Metal AIR caches under
    /// `<bundle-id>/com.apple.metal/` that the top-level catch-all rule
    /// can't see.
    case darwinCachePerApp(subdir: String)

    /// Per-app subdirectory inside `~/Library/Caches/<app>/`. Probes every
    /// first-level child and emits one finding per match. Used for things
    /// like Sparkle's update download cache (`<bundle>/org.sparkle-project.Sparkle/`)
    /// that's installed inside each updatable app's user-cache directory.
    case libraryCachesPerApp(subdir: String)

    /// Per-app subdirectory inside `~/Library/Application Support/<app>/`.
    /// Probes every first-level child and emits one finding per match. The
    /// `<app>` segment is a display name for many apps (`Discord/`, `Slack/`)
    /// and a bundle ID for others — the matcher doesn't care, it just walks
    /// the children. Used for the Chromium cache trio (`Cache/`, `Code Cache/`,
    /// `GPUCache/`) that Electron apps universally inherit and that native
    /// apps occasionally use too.
    case libraryAppSupportPerApp(subdir: String)

    /// True for matchers that emit one finding per app/bundle and where the
    /// last path component is a generic subdir name (`Cache`, `com.apple.metal`,
    /// `org.sparkle-project.Sparkle`). Drives per-app grouping in the
    /// results view.
    var isPerBundle: Bool {
        perBundleSubdir != nil
    }

    /// The trailing subdirectory the per-bundle probe matched on, or nil
    /// for non-per-bundle matchers. Used by `Finding.bundleSegment` to
    /// know how many path components to walk up to reach the bundle root
    /// (one for `Cache`, two for `WebKit/NetworkCache`, …).
    var perBundleSubdir: String? {
        switch self {
        case .darwinCachePerApp(let s),
             .libraryCachesPerApp(let s),
             .libraryAppSupportPerApp(let s):
            return s
        default:
            return nil
        }
    }

    /// Glob pattern (gitignore-style) used sparingly — currently for `.egg-info`.
    case glob(pattern: String)

    /// Aggregate match: every directory with this exact name under the project root
    /// collapses into a single row per project. Used for `__pycache__`,
    /// `.ipynb_checkpoints`, etc.
    case aggregateByName(directoryName: String, requiredProjectMarkers: [String])
}

/// Preferred cleanup action. Trash is always the default; a library-backed
/// command is only used where Trash is actively worse (hardlink bookkeeping,
/// running daemons, etc.).
enum CleanAction: Sendable, Hashable {
    /// Lane 1 — reversible. `NSWorkspace.recycle`.
    case trash
    /// Lane 2 — runnable shell command via `Process`, no sudo.
    case cleanCommand(CleanCommandKind)
    /// Lane 3 — shell command that needs admin privileges; run via osascript
    /// `do shell script … with administrator privileges` (shows the native
    /// macOS password prompt). A single prompt per session — the Deleter
    /// batches all selected sudo commands into one osascript invocation.
    case shellSudo(SudoCommandKind)

    enum CleanCommandKind: String, Sendable, Hashable, Codable {
        case pnpmStorePrune
        case goModCacheClean
        case bazelExpunge
        case simctlDeleteUnavailable
        case ollamaRm
        case brewCleanup                     // `brew cleanup --prune=all`
        case simctlRuntimeDeleteUnavailable  // `xcrun simctl runtime delete unavailable`
    }

    enum SudoCommandKind: String, Sendable, Hashable, Codable {
        case nixCollectGarbage
        case nixLogsRm
        case macPortsCleanAll
        case kdkRm                           // per-item `rm -rf <path>` for KDKs
    }
}

/// Aggregation mode for presentation.
enum AggregationMode: Sendable, Hashable {
    case none
    case perProject
}

/// A single cleanup rule. Immutable. Sendable. Identified by `id`.
struct Rule: Sendable, Hashable, Identifiable {
    let id: String
    let displayName: String
    let ecosystem: Ecosystem
    let scope: Scope
    let matcher: Matcher
    let action: CleanAction
    let tier: RegenEffort
    let aggregation: AggregationMode
    /// Optional one-line description surfaced in the UI as secondary text.
    let notes: String?
    /// Bundled SVG asset name (without .svg). When nil, IconTile falls back to
    /// `sfSymbol`, then runtime-derived asset, then ecosystem default.
    let iconAsset: String?
    /// SF Symbol name to use when no bundled logo fits (e.g. Simulator).
    let sfSymbol: String?
    /// Explicit tile tint. Lets a rule override the ecosystem tint — e.g. Xcode
    /// and Simulator live under the "Swift / Objective-C" ecosystem (orange)
    /// but should render in Apple iOS blue.
    let brandTint: Color?
    /// How to interpret the measured size in the UI. Nil = exact reclaim.
    /// - `.upperBound` → "Up to X"
    /// - `.unknown`    → "TBD"       (used when there's no `customSizer`)
    let sizeHint: SizeHint?
    /// Custom sizer that replaces the default directory walk. Useful for
    /// rules where the "reclaimable" size isn't the dir size — e.g.
    /// `brew cleanup --dry-run` returns the exact predicted reclaim.
    /// While a custom sizer runs, the finding's `size` stays nil and the
    /// UI shows a shimmer placeholder.
    let customSizer: CustomSizerKind?

    /// Lookup key into `LanguageCatalog`. Shared across many rules that
    /// target the same language (every JS/TS rule uses `"javascript"`).
    /// Drives the language section of the info panel.
    let languageKey: String?

    /// Lookup key into `ToolCatalog` — identifies the specific tool that
    /// produced the artifact (e.g. `"vite"` for `.vite/`, `"pnpm"` for
    /// pnpm store). The info panel shows this section above the language.
    let toolKey: String?

    /// Per-item context — what this directory is, why it's safe to remove,
    /// and how to regenerate it. Populated inline in `RuleCatalog`.
    let item: ItemInfo?

    enum Scope: Sendable, Hashable, Codable {
        case projectLocal   // found by walker
        case globalCache    // found by fixed-path probe
        case perAppCache    // per-bundle Darwin-cache subdir; gated separately
                            // in the sidebar so the long tail of small per-app
                            // caches doesn't dominate the default scan.
    }

    init(
        id: String,
        displayName: String,
        ecosystem: Ecosystem,
        scope: Scope,
        matcher: Matcher,
        action: CleanAction,
        tier: RegenEffort,
        aggregation: AggregationMode,
        notes: String?,
        iconAsset: String? = nil,
        sfSymbol: String? = nil,
        brandTint: Color? = nil,
        sizeHint: SizeHint? = nil,
        customSizer: CustomSizerKind? = nil,
        languageKey: String? = nil,
        toolKey: String? = nil,
        item: ItemInfo? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.ecosystem = ecosystem
        self.scope = scope
        self.matcher = matcher
        self.action = action
        self.tier = tier
        self.aggregation = aggregation
        self.notes = notes
        self.iconAsset = iconAsset
        self.sfSymbol = sfSymbol
        self.brandTint = brandTint
        self.sizeHint = sizeHint
        self.customSizer = customSizer
        self.languageKey = languageKey
        self.toolKey = toolKey
        self.item = item
    }
}

/// Replaces the default directory walk for rules where the "reclaimable" size
/// can only be determined by the vendor's own dry-run / prediction.
enum CustomSizerKind: String, Sendable, Hashable, Codable {
    case brewCleanupDryRun               // `brew cleanup --dry-run --prune=all`
    case simctlDeleteUnavailable         // sum of sizes of every unavailable simulator device
    case simctlRuntimeDeleteUnavailable  // sum of sizes of every unavailable simulator runtime
}

/// How the UI should interpret a finding's measured size.
enum SizeHint: Sendable, Hashable, Codable {
    /// Size is a ceiling — actual reclaim is ≤ this. Rendered "Up to X".
    case upperBound
    /// Size can't be predicted without running the command. Rendered "TBD".
    case unknown
}
