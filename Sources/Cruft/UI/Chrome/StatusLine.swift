import SwiftUI

/// Finder-style status strip at the bottom of the window. Non-interactive
/// text; the primary "Move to Trash" button is in the toolbar. This exists
/// just to communicate totals + phase.
struct StatusLine: View {
    @Bindable var model: AppModel
    var onTrashTapped: () -> Void = {}

    var body: some View {
        HStack(spacing: 8) {
            // Phase glyph + status label are non-interactive — pass clicks
            // through to the WindowDragHandle behind so the text itself is a
            // draggable region, matching Finder's status bar.
            phaseIndicator
                .allowsHitTesting(false)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .allowsHitTesting(false)
            Spacer()
            if !model.selectedFindings.isEmpty {
                Text(selectionText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                    .allowsHitTesting(false)
                Button {
                    model.deselectAll()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Deselect all (⌘⇧A)")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(WindowDragHandle())
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(.separator), alignment: .top)
    }

    @ViewBuilder
    private var phaseIndicator: some View {
        switch model.phase {
        case .idle:
            Image(systemName: "circle.dotted").foregroundStyle(.secondary)
        case .discovering:
            ProgressView().controlSize(.mini)
        case .sizing:
            ProgressView(value: Double(model.sizedFindings),
                         total: Double(max(model.totalFindings, 1)))
                .progressViewStyle(.linear)
                .frame(width: 80)
        case .done:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        }
    }

    /// Headline count + reclaim size. Falls back to "N of M selected" when
    /// filters are hiding some of the underlying selection — makes the
    /// gap between raw selection and the delete scope visible instead of
    /// silently reporting fewer items than the user picked.
    private var selectionText: String {
        let visible = model.effectiveSelectedFindings.count
        let total = model.selection.count
        let sizeText = formatBytes(model.reclaimableBytes)
        if visible == total {
            return "\(visible) selected · \(sizeText)"
        }
        return "\(visible) of \(total) selected · \(sizeText)"
    }

    private var text: String {
        switch model.phase {
        case .idle:
            return "Ready"
        case .discovering:
            return "Scanning… \(model.totalFindings) found"
        case .sizing:
            return "Sizing \(model.sizedFindings) of \(model.totalFindings) — \(formatBytes(model.scannedBytes)) so far"
        case .done:
            let n = model.filteredFindings.count
            return "\(n) item\(n == 1 ? "" : "s") · \(formatBytes(model.filteredBytes)) reclaimable"
        }
    }
}
