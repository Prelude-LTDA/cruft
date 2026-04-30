import AppKit
import SwiftUI

/// Preview-before-commit sheet. Two orthogonal axes drive presentation:
///
/// - **Action axis** (groups items into lanes): Trash is reversible from
///   Finder; commands and sudo aren't.
/// - **Consequence axis** (per-row): `.extreme` items can't be regenerated
///   even if the action itself is reversible. They render with an opt-in
///   checkbox (default off) so they only proceed on explicit consent.
///
/// The destructive red treatment fires when *either* axis is irreversible:
/// any non-trash action OR any extreme item opted in.
struct ConfirmationSheet: View {
    let items: [Finding]
    let proceed: ([Finding]) -> Void
    let cancel: () -> Void

    @State private var optedInExtreme: Set<UInt64> = []

    private var trashItems: [Finding] {
        items.filter { $0.action == .trash }.sortedByEffortThenSize()
    }

    private var commandItems: [Finding] {
        items.filter {
            if case .cleanCommand = $0.action { return true }
            return false
        }.sortedByEffortThenSize()
    }

    private var sudoItems: [Finding] {
        items.filter {
            if case .shellSudo = $0.action { return true }
            return false
        }.sortedByEffortThenSize()
    }

    private var hasTrash: Bool { !trashItems.isEmpty }
    private var hasCommands: Bool { !commandItems.isEmpty }
    private var hasSudo: Bool { !sudoItems.isEmpty }
    private var hasIrreversibleAction: Bool { hasCommands || hasSudo }
    private var hasOptedInExtreme: Bool { !optedInExtreme.isEmpty }
    private var hasDestructiveStakes: Bool { hasIrreversibleAction || hasOptedInExtreme }

    private func isIncluded(_ f: Finding) -> Bool {
        f.tier != .extreme || optedInExtreme.contains(f.id)
    }

    private var includedItems: [Finding] { items.filter(isIncluded) }
    private var includedTrash: [Finding] { trashItems.filter(isIncluded) }
    private var includedCommands: [Finding] { commandItems.filter(isIncluded) }
    private var includedSudo: [Finding] { sudoItems.filter(isIncluded) }

    private var trashTotal: Int64 { includedTrash.reduce(0) { $0 + $1.reclaimBytes } }
    private var commandTotal: Int64 { includedCommands.reduce(0) { $0 + $1.reclaimBytes } }
    private var sudoTotal: Int64 { includedSudo.reduce(0) { $0 + $1.reclaimBytes } }
    private var grandTotal: Int64 { trashTotal + commandTotal + sudoTotal }

    private var primaryLabel: String {
        let n = includedItems.count
        if !includedSudo.isEmpty { return "Authenticate & Clean \(n) Items" }
        if !includedTrash.isEmpty && !includedCommands.isEmpty { return "Clean \(n) Items" }
        if !includedCommands.isEmpty { return "Run \(n == 1 ? "Command" : "\(n) Commands")" }
        return n == 1 ? "Move to Trash" : "Move \(n) Items to Trash"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if hasTrash {
                lane(
                    title: "Move to Trash",
                    subtitle: "Items go to the Trash and can be restored from Finder.",
                    systemImage: "trash",
                    iconColor: .blue,
                    included: includedTrash.count,
                    total: trashItems.count,
                    bytes: trashTotal
                ) {
                    ForEach(trashItems) { f in trashRow(f) }
                }
            }

            if hasCommands {
                lane(
                    title: "Run Commands",
                    subtitle: "Irreversible — each runs the tool's proper cleanup and can't be undone from Trash.",
                    systemImage: "terminal.fill",
                    iconColor: .red,
                    included: includedCommands.count,
                    total: commandItems.count,
                    bytes: commandTotal
                ) {
                    ForEach(commandItems) { f in commandRow(f) }
                }
            }

            if hasSudo {
                lane(
                    title: "Run with Admin Privileges",
                    subtitle: "Requires your password. Runs as root via a single macOS authentication prompt.",
                    systemImage: "lock.shield.fill",
                    iconColor: .red,
                    included: includedSudo.count,
                    total: sudoItems.count,
                    bytes: sudoTotal
                ) {
                    ForEach(sudoItems) { f in sudoRow(f) }
                }
            }

            footer
        }
        .padding(20)
        .frame(minWidth: 560, idealWidth: 620, minHeight: 340)
    }

    private var header: some View {
        let n = includedItems.count
        return HStack(spacing: 10) {
            Image(systemName: hasSudo ? "lock.shield.fill"
                   : (hasDestructiveStakes ? "exclamationmark.triangle.fill" : "trash"))
                .font(.largeTitle)
                .foregroundStyle(hasDestructiveStakes ? .red : .blue)
            VStack(alignment: .leading) {
                Text(hasIrreversibleAction ? "Clean \(n) Items" : "Move to Trash")
                    .font(.title2.bold())
                Text("\(n) item\(n == 1 ? "" : "s") · \(formatBytes(grandTotal))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if hasExtreme { extremeMasterToggle }
            Spacer()
            Button("Cancel", role: .cancel, action: cancel)
                .keyboardShortcut(.escape)
            let action = { proceed(includedItems) }
            if hasDestructiveStakes {
                Button(role: .destructive, action: action) { Text(primaryLabel) }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .keyboardShortcut(.defaultAction)
                    .disabled(includedItems.isEmpty)
            } else {
                Button(primaryLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(includedItems.isEmpty)
            }
        }
    }

    private var hasExtreme: Bool { !extremeIds.isEmpty }
    private var extremeIds: [UInt64] { items.compactMap { $0.tier == .extreme ? $0.id : nil } }

    private var extremeMasterState: NSControl.StateValue {
        let opted = extremeIds.filter { optedInExtreme.contains($0) }.count
        if opted == 0 { return .off }
        if opted == extremeIds.count { return .on }
        return .mixed
    }

    private func setAllExtreme(_ included: Bool) {
        if included { optedInExtreme.formUnion(extremeIds) }
        else { extremeIds.forEach { optedInExtreme.remove($0) } }
    }

    private var extremeMasterToggle: some View {
        let extremeCount = extremeIds.count
        let extremeBytes = items
            .filter { $0.tier == .extreme }
            .reduce(Int64(0)) { $0 + $1.reclaimBytes }
        let label = extremeCount == 1
            ? "Include extreme item"
            : "Include all \(extremeCount) extreme items"
        // The outer .fixedSize keeps the HStack from being stretched
        // vertically by the surrounding footer layout — the
        // NSViewRepresentable doesn't propagate a tight intrinsic height
        // and the row would otherwise expand to fill available space.
        return HStack(alignment: .firstTextBaseline, spacing: 8) {
            TriStateCheckbox(
                title: label,
                state: extremeMasterState,
                onToggle: { newState in
                    setAllExtreme(newState == .on)
                }
            )
            // SwiftUI doesn't bridge NSButton's text baseline, so report
            // it manually. The label inside a small-size checkbox sits near
            // the bottom of its bounds.
            .alignmentGuide(.firstTextBaseline) { d in d.height * 0.78 }
            Text("· \(formatBytes(extremeBytes))")
                .font(.caption).foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .fixedSize()
    }

    @ViewBuilder
    private func lane<Content: View>(
        title: String, subtitle: String, systemImage: String, iconColor: Color,
        included: Int, total: Int, bytes: Int64, @ViewBuilder rows: () -> Content
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundStyle(iconColor)
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(laneCountText(included: included, total: total, bytes: bytes))
                        .font(.caption).foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer()
                }
                Text(subtitle)
                    .font(.caption).foregroundStyle(.secondary)
                Divider()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) { rows() }
                        .padding(.vertical, 2)
                }
                .frame(maxHeight: 140)
            }
            .padding(4)
        }
    }

    private func laneCountText(included: Int, total: Int, bytes: Int64) -> String {
        let countPart = included == total ? "\(total)" : "\(included) of \(total)"
        return "· \(countPart) · \(formatBytes(bytes))"
    }

    @ViewBuilder
    private func trashRow(_ f: Finding) -> some View {
        rowToggleable(f) {
            HStack(spacing: 8) {
                tierGlyph(f.tier)
                Text((f.presentationPath as NSString).abbreviatingWithTildeInPath)
                    .lineLimit(1).truncationMode(.middle)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(isIncluded(f) ? .primary : .secondary)
                Spacer()
                Text(f.sizeText)
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func commandRow(_ f: Finding) -> some View {
        rowToggleable(f) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    tierGlyph(f.tier)
                    Text(f.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isIncluded(f) ? .primary : .secondary)
                    Spacer()
                    Text(f.sizeText)
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                }
                if let preview = Deleter.previewCommand(for: f) {
                    Text(preview)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 22)
                }
            }
        }
    }

    @ViewBuilder
    private func sudoRow(_ f: Finding) -> some View {
        rowToggleable(f) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    tierGlyph(f.tier)
                    Text(f.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isIncluded(f) ? .primary : .secondary)
                    Spacer()
                    Text(f.sizeText)
                        .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                }
                if let preview = Deleter.previewCommand(for: f) {
                    Text(preview)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 22)
                }
            }
        }
    }

    /// Wraps an extreme row's content as the label of a real `Toggle`. The
    /// whole row is the toggle's hit target, so the checkbox shows its
    /// normal pressed/highlight affordances no matter where the user clicks.
    /// Non-extreme rows pass through unchanged.
    @ViewBuilder
    private func rowToggleable<V: View>(_ f: Finding, @ViewBuilder content: () -> V) -> some View {
        if f.tier == .extreme {
            Toggle(isOn: optInBinding(f)) { content() }
                .toggleStyle(.checkbox)
        } else {
            content()
        }
    }

    private func optInBinding(_ f: Finding) -> Binding<Bool> {
        Binding(
            get: { optedInExtreme.contains(f.id) },
            set: { newValue in
                if newValue { optedInExtreme.insert(f.id) }
                else { optedInExtreme.remove(f.id) }
            }
        )
    }

    @ViewBuilder
    private func tierGlyph(_ tier: RegenEffort) -> some View {
        Image(systemName: tier.icon)
            .foregroundStyle(tier.tint)
            .frame(width: 14)
    }
}

/// macOS checkbox with on/off/mixed states. SwiftUI `Toggle` is Bool-only,
/// so we wrap `NSButton` to expose the indeterminate state used for "some
/// extreme items selected." Click cycles off↔on; mixed→on.
private struct TriStateCheckbox: NSViewRepresentable {
    let title: String
    let state: NSControl.StateValue
    let onToggle: (NSControl.StateValue) -> Void

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(checkboxWithTitle: title, target: context.coordinator,
                              action: #selector(Coordinator.click(_:)))
        button.allowsMixedState = true
        button.controlSize = .small
        button.font = NSFont.preferredFont(forTextStyle: .caption1)
        return button
    }

    func updateNSView(_ button: NSButton, context: Context) {
        button.title = title
        button.state = state
        button.allowsMixedState = true
        context.coordinator.previousState = state
        context.coordinator.onToggle = onToggle
    }

    func makeCoordinator() -> Coordinator { Coordinator(onToggle: onToggle) }

    final class Coordinator: NSObject {
        var onToggle: (NSControl.StateValue) -> Void
        var previousState: NSControl.StateValue = .off
        init(onToggle: @escaping (NSControl.StateValue) -> Void) { self.onToggle = onToggle }
        @MainActor @objc func click(_ sender: NSButton) {
            // Two-step toggle (off ↔ on); from mixed, click means "select
            // everything." NSButton's native cycle is off→on→mixed, so we
            // override based on the state we observed before the click.
            let next: NSControl.StateValue = previousState == .on ? .off : .on
            sender.state = next
            previousState = next
            onToggle(next)
        }
    }
}

private extension Array where Element == Finding {
    /// Highest restoration effort first (Extreme → Low); ties broken by larger size first.
    func sortedByEffortThenSize() -> [Finding] {
        sorted { lhs, rhs in
            if lhs.tier != rhs.tier { return lhs.tier > rhs.tier }
            return lhs.reclaimBytes > rhs.reclaimBytes
        }
    }
}
