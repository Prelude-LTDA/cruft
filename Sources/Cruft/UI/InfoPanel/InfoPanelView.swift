import SwiftUI
import AppKit

/// Right-side inspector showing details for the current selection.
///
/// States:
///   - empty           → hint placeholder
///   - single finding  → item / tool / language sections
///   - multi selection → summary stats
struct InfoPanelView: View {
    @Bindable var model: AppModel

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        // Route through `effectiveSelectedFindings` — only selections
        // currently visible under active filters drive what the panel
        // shows. Hidden selections stay warm in `model.selection` but
        // don't surface here until a filter reveals them.
        let selected = model.effectiveSelectedFindings
        if selected.isEmpty {
            emptyState
        } else if selected.count == 1 {
            singleDetail(selected[0])
        } else {
            multiSummary(selected)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Give the user the same overall size/breakdown read as the
            // multi-select summary, applied to everything currently
            // passing filters. Keeps the panel useful even when nothing
            // is selected yet.
            if !model.filteredFindings.isEmpty {
                summaryBlock(
                    items: model.filteredFindings,
                    title: "\(model.filteredFindings.count) items"
                )

                sectionDivider
            }

            VStack(alignment: .center, spacing: 12) {
                Image(systemName: "sidebar.trailing")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("No Selection")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Select an item to see what it is, if it's safe to remove, and how to regenerate it.")
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        }
    }

    // MARK: - Single

    @ViewBuilder
    private func singleDetail(_ f: Finding) -> some View {
        if let rule = RuleCatalog.rule(id: f.ruleId) {
            let tool = ToolCatalog.info(for: rule.toolKey)
            // Language falls back to the tool's parent language so rules
            // that only set `toolKey` still surface the language section.
            let lang = LanguageCatalog.info(for: rule.languageKey ?? tool?.languageKey)
            let eco = EcosystemCatalog.info(for: rule.ecosystem)

            VStack(alignment: .leading, spacing: 0) {
                header(for: f, rule: rule)
                    .padding(.bottom, 18)

                pathBlock(for: f)
                sectionDivider

                if let item = rule.item {
                    InfoSection(title: "What is this?", collapseKey: "item") {
                        Text(.init(item.description))
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        if let safety = item.safetyNote {
                            SafetyNoteBlock(text: safety, tier: rule.tier)
                        }
                        if let cmd = f.effectiveRegenCommand(rule: rule) {
                            RegenCommandBlock(command: cmd)
                        }
                        if !item.links.isEmpty {
                            InfoLinkList(links: item.links)
                        }
                    }
                    if tool != nil || eco != nil || lang != nil {
                        sectionDivider
                    }
                }

                if let tool {
                    InfoSection(title: "About \(tool.displayName)", collapseKey: "tool") {
                        Text(.init(tool.tagline))
                            .font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !tool.description.isEmpty {
                            Text(.init(tool.description))
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !tool.links.isEmpty {
                            InfoLinkList(links: tool.links)
                        }
                    }
                    if lang != nil || eco != nil {
                        sectionDivider
                    }
                }

                if let lang {
                    InfoSection(title: "About \(lang.displayName)", collapseKey: "language") {
                        Text(.init(lang.tagline))
                            .font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !lang.description.isEmpty {
                            Text(.init(lang.description))
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !lang.links.isEmpty {
                            InfoLinkList(links: lang.links)
                        }
                    }
                    if eco != nil {
                        sectionDivider
                    }
                }

                if let eco {
                    InfoSection(title: "About \(eco.displayName)", collapseKey: "ecosystem") {
                        Text(.init(eco.tagline))
                            .font(.callout).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        if !eco.description.isEmpty {
                            Text(.init(eco.description))
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if !eco.links.isEmpty {
                            InfoLinkList(links: eco.links)
                        }
                    }
                }
            }
        }
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.vertical, 16)
    }

    private func header(for f: Finding, rule: Rule) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconTile(finding: f, rule: rule, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(rule.displayName)
                    .font(.headline)
                if let note = rule.notes {
                    Text(note)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func pathBlock(for f: Finding) -> some View {
        InfoSection(title: "Location", collapseKey: "location") {
            Text(f.presentationPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Button {
                    FindingActions.showInFinder([f.presentationPath])
                } label: {
                    Label("Finder", systemImage: "finder")
                }
                Button {
                    FindingActions.openInTerminal([f.presentationPath])
                } label: {
                    Label("Terminal", systemImage: "terminal")
                }
                Button {
                    FindingActions.copyPath([f.presentationPath])
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
            }
            .labelStyle(.titleAndIcon)
            .font(.callout)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    // MARK: - Multi

    private func multiSummary(_ items: [Finding]) -> some View {
        summaryBlock(items: items, title: "\(items.count) items selected")
    }

    /// Shared Reclaimable + Breakdown block used both by the multi-select
    /// summary and the empty-state ("N items match the current filters").
    /// The header text (`title`) is the only thing that changes between
    /// the two contexts.
    private func summaryBlock(items: [Finding], title: String) -> some View {
        // A finding is "pending" if its size hasn't been computed yet and
        // its rule doesn't declare the size as permanently unknown (the
        // latter — like `brew cleanup` dry-run — contributes zero bytes
        // by design and doesn't count as pending).
        let pendingTotal = items.filter {
            $0.size == nil && $0.sizeHint != .unknown
        }.count
        let total = items.reduce(Int64(0)) { $0 + $1.reclaimBytes }
        let slices: [EcoSlice] = Dictionary(grouping: items, by: \.ecosystem)
            .map { (eco, arr) in
                EcoSlice(
                    ecosystem: eco,
                    count: arr.count,
                    bytes: arr.reduce(0) { $0 + $1.reclaimBytes },
                    pending: arr.filter { $0.size == nil && $0.sizeHint != .unknown }.count
                )
            }
            .sorted { lhs, rhs in
                // Primary: size desc. Secondary: count desc — gives a
                // sensible early-scan order while everything is still nil
                // (every slice has 0 bytes, so the "biggest by count"
                // wins). Tertiary: displayName asc (what the user sees) —
                // final tie-breaker so identical bytes+count never shuffle
                // between renders.
                if lhs.bytes != rhs.bytes { return lhs.bytes > rhs.bytes }
                if lhs.count != rhs.count { return lhs.count > rhs.count }
                return lhs.ecosystem.displayName.localizedCaseInsensitiveCompare(rhs.ecosystem.displayName) == .orderedAscending
            }
        // Equatable signature that changes when slice order, byte counts,
        // or pending counts change. Drives `.animation(_:value:)` so the
        // Breakdown rows reorder smoothly and the stacked bar segments
        // resize between scan ticks instead of snapping.
        let slicesSignature = slices.map {
            "\($0.ecosystem.rawValue):\($0.bytes):\($0.pending):\($0.count)"
        }

        return VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3).fontWeight(.semibold)

            InfoSection(title: "Reclaimable") {
                // Headline total: while no bytes are known yet, show
                // "Calculating…" instead of a partial sum the user might
                // misread as final. Once any size lands, the byte total
                // takes over.
                if pendingTotal > 0 && total == 0 {
                    Text("Calculating…")
                        .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Text(formatBytes(total))
                        .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                        .foregroundStyle(.primary)
                }
                // Bar appears as soon as we have any sized bytes — segments
                // are proportional to the *known* total, and the existing
                // `.animation(_:value:)` on segment widths smoothly redraws
                // the composition as more sizes arrive. Ecosystems whose
                // items are still pending contribute zero width until
                // their sizes land, then expand into place.
                if total > 0 {
                    StackedSizeBar(slices: slices, total: total)
                        .padding(.top, 4)
                        .transition(.opacity)
                        .animation(.smooth(duration: 0.5), value: slicesSignature)
                }
            }
            // Drive the bar's appearance transition (`if total > 0`) — the
            // `.transition(.opacity)` on the bar only fires inside an
            // animation scope, and we want to scope it tightly enough that
            // the headline byte text doesn't get pulled in.
            .animation(.smooth(duration: 0.5), value: total > 0)

            InfoSection(title: "Breakdown") {
                ForEach(slices, id: \.ecosystem) { slice in
                    HStack(spacing: 8) {
                        Circle().fill(slice.ecosystem.tint).frame(width: 8, height: 8)
                        Text(slice.ecosystem.displayName).font(.callout)
                        Spacer()
                        if slice.pending > 0 {
                            // Em-dash as the "still being computed" placeholder;
                            // keeps the row layout stable without flashing zero.
                            Text("—")
                                .font(.callout).foregroundStyle(.tertiary)
                                .monospacedDigit()
                        } else {
                            Text(formatBytes(slice.bytes))
                                .font(.callout).foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Text("·").foregroundStyle(.tertiary)
                        Text("\(slice.count)")
                            .font(.callout).foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            .animation(.smooth(duration: 0.5), value: slicesSignature)
        }
    }
}

// MARK: - Stacked size bar

/// Horizontal stacked-segment bar à la macOS's "About This Mac → Storage"
/// visualisation. Each segment's width is proportional to its share of the
/// total; colors come from the ecosystem tint. Used in the multi-select
/// summary to show the size composition of the selection at a glance.
struct EcoSlice {
    let ecosystem: Ecosystem
    let count: Int
    let bytes: Int64
    /// Items in this slice that are still being sized (size == nil, and
    /// not marked as permanently unknown). Drives the "—" placeholder in
    /// the breakdown list until the sizer catches up.
    var pending: Int = 0
}

struct StackedSizeBar: View {
    let slices: [EcoSlice]
    let total: Int64
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(slices, id: \.ecosystem) { slice in
                    slice.ecosystem.tint
                        .frame(width: width(for: slice, total: geo.size.width))
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: height / 3, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: height / 3, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func width(for slice: EcoSlice, total barWidth: CGFloat) -> CGFloat {
        guard total > 0 else { return 0 }
        let fraction = Double(slice.bytes) / Double(total)
        // Clamp tiny slices to at least 2pt so a single pixel of colour is
        // still discernible — the bar would otherwise read as missing an
        // ecosystem entirely.
        return max(2, CGFloat(fraction) * barWidth)
    }
}

// MARK: - Section

/// Titled block with a subtle divider and consistent spacing.
///
/// When `collapseKey` is provided, the header becomes an accordion toggle with
/// a chevron, and the expansion state persists across launches keyed by the
/// given string (e.g. `"item"`, `"tool"`, `"language"`, `"ecosystem"`,
/// `"location"`). The key is intentionally section-type-scoped, not
/// title-scoped — switching from "About pnpm" to "About bun" preserves the
/// "tool section is open" state instead of treating them as different things.
struct InfoSection<Content: View>: View {
    let title: String
    let collapseKey: String?
    @ViewBuilder let content: () -> Content

    @State private var expanded: Bool

    init(
        title: String,
        collapseKey: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.collapseKey = collapseKey
        self.content = content
        // Resolve initial expansion from UserDefaults, defaulting to open.
        let initial: Bool
        if let key = collapseKey {
            let storageKey = Self.storageKey(for: key)
            if UserDefaults.standard.object(forKey: storageKey) != nil {
                initial = UserDefaults.standard.bool(forKey: storageKey)
            } else {
                initial = true
            }
        } else {
            initial = true
        }
        _expanded = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if expanded {
                content()
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        if let key = collapseKey {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
                UserDefaults.standard.set(expanded, forKey: Self.storageKey(for: key))
            } label: {
                headerLabel(showChevron: true)
            }
            .buttonStyle(.plain)
        } else {
            headerLabel(showChevron: false)
        }
    }

    private func headerLabel(showChevron: Bool) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .tracking(0.6)
            if showChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(expanded ? 0 : -90))
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private static func storageKey(for key: String) -> String {
        "regen.info.section.\(key).expanded.v1"
    }
}

// MARK: - Links

struct InfoLinkList: View {
    let links: [InfoLink]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(sorted, id: \.url) { link in
                InfoLinkButton(link: link)
            }
        }
        .padding(.top, 2)
    }

    private var sorted: [InfoLink] {
        // Kind order: official > docs > blog > issue > stackOverflow > forum > other
        let rank: [InfoLink.Kind: Int] = [
            .official: 0, .docs: 1, .blog: 2,
            .issue: 3, .stackOverflow: 4, .forum: 5, .other: 6,
        ]
        return links.sorted { (rank[$0.kind] ?? 99) < (rank[$1.kind] ?? 99) }
    }
}

struct InfoLinkButton: View {
    let link: InfoLink
    @State private var hovered = false

    var body: some View {
        Button {
            if let url = URL(string: link.url) {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 14)
                    .foregroundStyle(.tint)
                Text(link.title)
                    .font(.callout)
                    .foregroundStyle(.tint)
                    .underline(hovered, color: .accentColor)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right.square")
                    .font(.callout)
                    .foregroundStyle(.tint)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .onHover { hovered = $0 }
    }

    /// Icon chosen from `InfoLink.Kind`. Semantic mapping:
    ///   - `.official` — vendor/product homepage → `house`
    ///   - `.docs`     — reference or how-to docs (MDN, project docs) → `book`
    ///   - `.wiki`     — Wikipedia / community wiki → `puzzlepiece`
    ///   - `.issue`    — bug tracker → `ant`
    ///   - `.stackOverflow` → `bubble.left.and.bubble.right`
    ///   - `.blog`     → `text.alignleft`
    ///   - `.forum`    → `person.2`
    ///   - `.other`    → `link`
    private var icon: String {
        switch link.kind {
        case .official: "house"
        case .docs: "book"
        case .wiki: "puzzlepiece"
        case .issue: "ant"
        case .stackOverflow: "bubble.left.and.bubble.right"
        case .blog: "text.alignleft"
        case .forum: "person.2"
        case .other: "link"
        }
    }
}

// MARK: - Safety note block

/// "Is this safe to delete?" callout. Green shield + short explanation by
/// default; `.extreme`-tier rules (AI chat history, unlocked node_modules,
/// etc.) swap the shield for an orange warning triangle so the user can't
/// miss that this one isn't the usual reclaim-and-forget case.
struct SafetyNoteBlock: View {
    let text: String
    let tier: RegenEffort

    var body: some View {
        // Bolded verdict prefix ("Yes." for reversible tiers, "Potentially
        // no." for extreme) sits inline at the start of the note so the
        // answer is immediately visible before the user reads the details.
        let prefix = tier == .extreme ? "**Potentially no.**" : "**Yes.**"
        VStack(alignment: .leading, spacing: 4) {
            Text("Is This Safe to Delete?")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Label {
                Text(.init("\(prefix) \(text)")).font(.callout)
            } icon: {
                if tier == .extreme {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "checkmark.shield")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Regen command block

struct RegenCommandBlock: View {
    let command: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Regeneration Command")
                .font(.caption).fontWeight(.semibold)
                .foregroundStyle(.secondary)
            HStack(alignment: .center, spacing: 8) {
                Text(command)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(.quaternary.opacity(0.5))
                    )
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy command")
            }
        }
        .padding(.top, 4)
    }
}
