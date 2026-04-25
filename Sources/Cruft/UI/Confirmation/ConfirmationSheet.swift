import SwiftUI

/// Preview-before-commit sheet. Groups items into two lanes by action:
/// - **Trash** — reversible (`NSWorkspace.recycle`, Put Back from Finder).
/// - **Run commands** — irreversible (`pnpm store prune`, `ollama rm`, etc.).
///   These reclaim more cleanly than Trash but can't be undone.
///
/// When any lane-2 item is selected, the primary button uses a destructive
/// (red) tint — a single visual cue that we're past the point of "just send
/// it to Trash, no harm done."
struct ConfirmationSheet: View {
    let items: [Finding]
    let proceed: () -> Void
    let cancel: () -> Void

    private var trashItems: [Finding] {
        items.filter { $0.action == .trash }
    }

    private var commandItems: [Finding] {
        items.filter {
            if case .cleanCommand = $0.action { return true }
            return false
        }
    }

    private var sudoItems: [Finding] {
        items.filter {
            if case .shellSudo = $0.action { return true }
            return false
        }
    }

    private var hasTrash: Bool { !trashItems.isEmpty }
    private var hasCommands: Bool { !commandItems.isEmpty }
    private var hasSudo: Bool { !sudoItems.isEmpty }
    private var hasIrreversible: Bool { hasCommands || hasSudo }

    private var trashTotal: Int64 { trashItems.reduce(0) { $0 + $1.reclaimBytes } }
    private var commandTotal: Int64 { commandItems.reduce(0) { $0 + $1.reclaimBytes } }
    private var sudoTotal: Int64 { sudoItems.reduce(0) { $0 + $1.reclaimBytes } }
    private var grandTotal: Int64 { trashTotal + commandTotal + sudoTotal }

    private var primaryLabel: String {
        if hasSudo { return "Authenticate & Clean \(items.count) Items" }
        if hasTrash && hasCommands { return "Clean \(items.count) Items" }
        if hasTrash { return "Move to Trash" }
        return "Run Commands"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if hasTrash {
                lane(
                    title: "Move to Trash",
                    subtitle: "Reversible — items go to the Trash and can be restored from Finder.",
                    systemImage: "trash",
                    iconColor: .blue,
                    count: trashItems.count,
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
                    count: commandItems.count,
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
                    count: sudoItems.count,
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
        HStack(spacing: 10) {
            Image(systemName: hasSudo ? "lock.shield.fill"
                   : (hasCommands ? "exclamationmark.triangle.fill" : "trash"))
                .font(.largeTitle)
                .foregroundStyle(hasIrreversible ? .red : .blue)
            VStack(alignment: .leading) {
                Text(hasIrreversible ? "Clean \(items.count) Items" : "Move to Trash")
                    .font(.title2.bold())
                Text("\(items.count) item\(items.count == 1 ? "" : "s") · \(formatBytes(grandTotal))")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text(footerText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Cancel", role: .cancel, action: cancel)
                .keyboardShortcut(.escape)
            if hasIrreversible {
                Button(role: .destructive, action: proceed) { Text(primaryLabel) }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .keyboardShortcut(.defaultAction)
            } else {
                Button(primaryLabel, action: proceed)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var footerText: String {
        if hasSudo {
            return "Admin commands run as root and can't be undone. You'll be asked for your password once."
        }
        if hasCommands {
            return "Commands can't be undone. Trash items can be restored from Finder."
        }
        return "Items go to the Trash and can be restored from Finder."
    }

    @ViewBuilder
    private func lane<Content: View>(
        title: String, subtitle: String, systemImage: String, iconColor: Color,
        count: Int, bytes: Int64, @ViewBuilder rows: () -> Content
    ) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: systemImage)
                        .foregroundStyle(iconColor)
                    Text(title).font(.subheadline.weight(.semibold))
                    Text("· \(count) · \(formatBytes(bytes))")
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

    @ViewBuilder
    private func trashRow(_ f: Finding) -> some View {
        HStack(spacing: 8) {
            tierGlyph(f.tier)
            Text((f.presentationPath as NSString).abbreviatingWithTildeInPath)
                .lineLimit(1).truncationMode(.middle)
                .font(.system(.caption, design: .monospaced))
            Spacer()
            Text(f.sizeText)
                .font(.caption).monospacedDigit().foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func commandRow(_ f: Finding) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                tierGlyph(f.tier)
                Text(f.displayName)
                    .font(.caption.weight(.semibold))
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

    @ViewBuilder
    private func sudoRow(_ f: Finding) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                tierGlyph(f.tier)
                Text(f.displayName)
                    .font(.caption.weight(.semibold))
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

    @ViewBuilder
    private func tierGlyph(_ tier: RegenEffort) -> some View {
        Image(systemName: tier.icon)
            .foregroundStyle(tier.tint)
            .frame(width: 14)
    }
}
