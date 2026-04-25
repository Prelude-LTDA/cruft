import Foundation

/// A single discovered cleanup target. Emitted by the discovery coordinator into
/// the UI stream. Value-typed, cheap to copy, Hashable by `id`.
struct Finding: Sendable, Hashable, Identifiable {
    /// Stable hash of `(deviceID, inode)` or `(ruleId, canonicalPath)`.
    let id: UInt64

    /// Rule that produced this finding.
    let ruleId: String
    let ecosystem: Ecosystem
    let tier: RegenEffort
    let action: CleanAction

    /// The canonical path — symlinks resolved, lowercased on case-insensitive
    /// volumes. Used for dedup.
    let canonicalPath: String

    /// The presentation path — the *unresolved* URL, so Trash moves the symlink
    /// itself rather than walking into its target. See security round #1.
    let presentationPath: String

    /// Project anchor (the directory containing the marker file), or nil if this
    /// is a global cache.
    let projectPath: String?

    /// Name to display for the project ("my-app") — nil for global caches.
    let projectName: String?

    /// Runtime overlay (npm vs pnpm vs yarn vs bun for node_modules, etc.).
    let runtime: Runtime?

    /// Device ID + inode tuple for the directory itself. Used by the inode-sharded
    /// sizer to skip hardlink double-counting. Packed: high 16 bits = dev, low 48
    /// bits = inode.
    let devInode: UInt64

    /// Size in bytes. `nil` means "still being calculated" — the UI renders a
    /// shimmer placeholder. Populated after the sizer completes.
    var size: Int64?

    /// Last-modified time of the containing directory (not contents).
    let modified: Date?

    /// True if `presentationPath` is a symlink whose target resolves outside
    /// the project root or outside `$HOME`. Confirmation sheet flags these.
    let suspiciousSymlink: Bool

    /// Count of child items aggregated into this finding (1 for non-aggregates).
    let aggregatedCount: Int

    /// Extra per-path records for aggregated findings (`__pycache__`, etc.).
    /// Empty for non-aggregates.
    let aggregatedChildren: [String]

    /// True if this finding came from Spotlight rather than the per-root
    /// walker. The UI dims these and the user can toggle the source on/off.
    var fromSpotlight: Bool = false

    /// How to interpret `size` in the UI. Nil = exact reclaim.
    var sizeHint: SizeHint? = nil

    var displayName: String {
        URL(fileURLWithPath: presentationPath).lastPathComponent
    }
}

extension Finding {
    // MARK: - Sort keys (for `KeyPathComparator<Finding>` in the flat table)
    //
    // `size` and `modified` are optional on the value type itself; Swift's
    // `KeyPathComparator` needs a non-optional Comparable to key off of.
    // Nil values coalesce to a sentinel that lands at the end of a
    // descending sort (which is the default), which matches user
    // intuition — items still being sized / without a timestamp sink to
    // the bottom of the list.

    var sizeSortKey: Int64 { size ?? 0 }
    var modifiedSortKey: Date { modified ?? .distantPast }
    /// Type column sorts by the rule's displayName, falling back to the raw
    /// rule id when a rule is missing (should not happen in practice).
    var typeSortKey: String {
        RuleCatalog.rule(id: ruleId)?.displayName ?? ruleId
    }

    /// The regen command shown in the info panel. For rules that depend on
    /// the detected runtime — chiefly `node.modules`, where the right
    /// command is `npm install` vs `pnpm install` vs `yarn install` vs
    /// `bun install` — this picks the runtime-specific form. Falls back to
    /// the rule's static `item.regenCommand` otherwise.
    func effectiveRegenCommand(rule: Rule) -> String? {
        if ruleId == "node.modules", let rt = runtime {
            switch rt {
            case .npm:   return "npm install"
            case .pnpm:  return "pnpm install"
            case .yarn:  return "yarn install"
            case .bun:   return "bun install"
            case .deno:  return "deno install"
            default:     break   // non-node runtimes can't resolve here
            }
        }
        return rule.item?.regenCommand
    }

    /// Short, human-readable size, or "—" while pending, or "TBD" when the
    /// rule says the actual reclaim isn't predictable from disk size.
    var sizeText: String {
        switch sizeHint {
        case .unknown: return "TBD"
        case .upperBound:
            guard let size else { return "—" }
            return "Up to \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))"
        case nil:
            guard let size else { return "—" }
            return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
    }

    /// Bytes to credit to a reclaim total. Zero for `.unknown` rules
    /// (`brew cleanup`), which would otherwise inflate headline numbers
    /// the user won't actually recover.
    var reclaimBytes: Int64 {
        sizeHint == .unknown ? 0 : (size ?? 0)
    }
}
