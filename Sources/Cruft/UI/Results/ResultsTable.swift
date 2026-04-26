import SwiftUI
import AppKit

/// The main findings list. Two modes, toggled by `model.useProjectGrouping`:
/// - Grouped: `List` with `Section` per project; shows project header rollup.
/// - Flat: SwiftUI `Table` with sortable columns.
///
/// Started with pure SwiftUI under the reasoning that most dev machines top
/// out in the low thousands of findings, not 50k. If perf profiling ever
/// justifies it, the flat variant can be swapped for an NSViewRepresentable.
struct ResultsTable: View {
    @Bindable var model: AppModel

    var body: some View {
        if model.useProjectGrouping {
            GroupedResults(model: model)
        } else {
            FlatResults(model: model)
        }
    }
}

// MARK: - Grouped (project-oriented)

private struct GroupedResults: View {
    @Bindable var model: AppModel

    var body: some View {
        List(selection: $model.selection) {
            ForEach(model.projectGroups) { group in
                Section {
                    ForEach(group.findings) { finding in
                        ResultRow(finding: finding, rule: rule(for: finding))
                            .tag(finding.id)
                    }
                } header: {
                    ProjectHeader(group: group)
                }
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .contextMenu(forSelectionType: UInt64.self, menu: contextMenu, primaryAction: showInFinder)
    }

    private func rule(for finding: Finding) -> Rule {
        RuleCatalog.rule(id: finding.ruleId)
            ?? Rule(id: "unknown", displayName: "Unknown", ecosystem: .node,
                    scope: .projectLocal,
                    matcher: .marker(directoryName: "", requiredMarkers: []),
                    action: .trash, tier: .high, aggregation: .none,
                    notes: nil, iconAsset: nil)
    }

    private func contextMenu(ids: Set<UInt64>) -> some View {
        FindingActions.contextButtons(for: paths(for: ids))
    }

    private func showInFinder(_ ids: Set<UInt64>) {
        FindingActions.showInFinder(paths(for: ids))
    }

    private func paths(for ids: Set<UInt64>) -> [String] {
        model.findings.filter { ids.contains($0.id) }.map(\.presentationPath)
    }
}

private struct ProjectHeader: View {
    let group: ProjectGroup

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: group.isGlobal ? "house.fill" : "folder.fill")
                .foregroundStyle(group.isGlobal ? .blue : .secondary)
            Text(group.displayName)
                .font(.system(size: 13, weight: .semibold))
            Text("·")
                .foregroundStyle(.tertiary)
            Text("\(group.findings.count) item\(group.findings.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatBytes(group.totalSize))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Flat (rule-oriented, sortable)

private struct FlatResults: View {
    @Bindable var model: AppModel

    /// Sort descriptors for the flat Table. Defaults to Size descending, which
    /// matches the grouped view's "biggest wins first" ordering. Click any
    /// column header to change.
    @State private var sortOrder: [KeyPathComparator<Finding>] = [
        KeyPathComparator(\.sizeSortKey, order: .reverse)
    ]

    var body: some View {
        // Column width ratios: Path 50%, Type 20%, Modified 15%, Size 15%.
        // SwiftUI Table widths are absolute; we set `ideal` values in the
        // target ratio so the initial layout matches, and users can still
        // drag to resize.
        Table(sortedFindings(), selection: $model.selection, sortOrder: $sortOrder) {
            TableColumn("") { finding in
                if let rule = RuleCatalog.rule(id: finding.ruleId) {
                    IconTile(finding: finding, rule: rule, size: 22)
                        .opacity(finding.fromSpotlight ? 0.55 : 1.0)
                }
            }.width(30)

            TableColumn("Path", value: \.presentationPath) { finding in
                // Keep the Path column single-line so every row has the same
                // height — the project-name subtitle that used to live here
                // made rows with a project taller than rows without one.
                // Project info is still visible via project grouping and the
                // Type column.
                HStack(spacing: 6) {
                    Text(displayPath(finding))
                        .lineLimit(1).truncationMode(.middle)
                    if finding.fromSpotlight {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("Found via Spotlight — outside your configured roots.")
                    }
                    if finding.tier > .low {
                        Image(systemName: finding.tier.icon)
                            .font(.caption)
                            .foregroundStyle(finding.tier.tint)
                            .help(finding.tier.title)
                    }
                }
                .opacity(finding.fromSpotlight ? 0.65 : 1.0)
            }
            .width(min: 180, ideal: 500)

            TableColumn("Type", value: \.typeSortKey) { finding in
                Text(RuleCatalog.rule(id: finding.ruleId)?.displayName ?? finding.ruleId)
                    .font(.caption).foregroundStyle(.secondary)
                    .opacity(finding.fromSpotlight ? 0.65 : 1.0)
            }
            .width(min: 90, ideal: 200)

            TableColumn("Modified", value: \.modifiedSortKey) { finding in
                Text(DateDisplay.relativeText(finding.modified))
                    .font(.caption).foregroundStyle(.secondary)
                    .help(DateDisplay.absoluteText(finding.modified))
                    .opacity(finding.fromSpotlight ? 0.65 : 1.0)
            }
            .width(min: 80, ideal: 150)

            TableColumn("Last Cleaned", value: \.lastCleanedSortKey) { finding in
                // Empty (rather than "—") for never-cleaned rows: most rows
                // start unclean, and a column full of dashes reads as noise.
                if let cleaned = finding.lastCleanedAt {
                    Text(DateDisplay.relativeText(cleaned))
                        .font(.caption).foregroundStyle(.secondary)
                        .help(DateDisplay.absoluteText(cleaned))
                        .opacity(finding.fromSpotlight ? 0.65 : 1.0)
                } else {
                    Text("")
                }
            }
            .width(min: 80, ideal: 150)

            TableColumn("Size", value: \.sizeSortKey) { finding in
                HStack {
                    Spacer(minLength: 0)
                    if finding.size != nil {
                        Text(finding.sizeText).monospacedDigit()
                    } else {
                        ShimmerPlaceholder()
                    }
                }
                .opacity(finding.fromSpotlight ? 0.65 : 1.0)
            }
            .width(min: 70, ideal: 150)
        }
        .contextMenu(forSelectionType: UInt64.self, menu: contextMenu, primaryAction: showInFinder)
    }

    private func contextMenu(ids: Set<UInt64>) -> some View {
        FindingActions.contextButtons(for: paths(for: ids))
    }

    private func showInFinder(_ ids: Set<UInt64>) {
        FindingActions.showInFinder(paths(for: ids))
    }

    private func paths(for ids: Set<UInt64>) -> [String] {
        model.findings.filter { ids.contains($0.id) }.map(\.presentationPath)
    }

    private func sortedFindings() -> [Finding] {
        // Apply user-chosen `sortOrder` on top of the model's filtered list.
        // Model returns size-desc by default; our default `sortOrder` matches,
        // so first render is unchanged. Clicking a column header re-sorts.
        model.filteredFindings.sorted(using: sortOrder)
    }

    private func displayPath(_ f: Finding) -> String {
        (f.presentationPath as NSString).abbreviatingWithTildeInPath
    }
}

// MARK: - Shared pieces

struct ResultRow: View {
    let finding: Finding
    let rule: Rule

    var body: some View {
        HStack(spacing: 10) {
            IconTile(finding: finding, rule: rule, size: 28)
                .opacity(finding.fromSpotlight ? 0.55 : 1.0)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(finding.displayName)
                        .font(.system(size: 13, weight: .medium))
                    if finding.fromSpotlight {
                        Image(systemName: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .help("Found via Spotlight — outside your configured roots.")
                    }
                    if finding.tier > .low {
                        Image(systemName: finding.tier.icon)
                            .font(.caption)
                            .foregroundStyle(finding.tier.tint)
                            .help(finding.tier.title)
                    }
                    if finding.suspiciousSymlink {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .help("Symlink resolves outside the project root.")
                    }
                }
                HStack(spacing: 6) {
                    Text((finding.presentationPath as NSString).abbreviatingWithTildeInPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text("·").foregroundStyle(.tertiary)
                    Text(rule.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: true, vertical: false)
                    if let r = finding.runtime {
                        Text("·").foregroundStyle(.tertiary)
                        Text(r.displayName).font(.caption).foregroundStyle(.secondary)
                    }
                    Text("·").foregroundStyle(.tertiary)
                    Text(DateDisplay.relativeText(finding.modified))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .help(DateDisplay.absoluteText(finding.modified))
                    if let cleaned = finding.lastCleanedAt {
                        Text("·").foregroundStyle(.tertiary)
                        // Manual HStack instead of `Label` — Label's icon/title
                        // gap is wider than the inline cadence of this row, and
                        // labelStyle doesn't expose a knob for it.
                        HStack(spacing: 3) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Last cleaned " + DateDisplay.relativeText(cleaned))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .help("Last cleaned via Cruft on \(DateDisplay.absoluteText(cleaned))")
                    }
                }
            }
            Spacer()
            if finding.size != nil {
                Text(finding.sizeText)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            } else {
                ShimmerPlaceholder()
            }
        }
        .padding(.vertical, 4)
        .opacity(finding.fromSpotlight ? 0.65 : 1.0)
    }
}

struct ShimmerPlaceholder: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.15))
            .overlay(
                LinearGradient(
                    colors: [.clear, Color.primary.opacity(0.1), .clear],
                    startPoint: .leading, endPoint: .trailing
                )
                .offset(x: phase)
                .mask(RoundedRectangle(cornerRadius: 3))
            )
            .frame(width: 60, height: 10)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 80
                }
            }
    }
}
