import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Horizontal row of multi-select ecosystem filter checkboxes. Uses the native
/// macOS checkbox (`Toggle.toggleStyle(.checkbox)`) tinted per-ecosystem —
/// on macOS 26 the `.tint(...)` modifier flows through to the checkbox fill.
///
/// Option-click on any chip solos that ecosystem (disables every other one);
/// option-clicking the already-soloed chip restores all. Matches the solo
/// convention used in Logic Pro, Finder tag filters, etc.
///
/// Chips can be dragged to reorder. We follow the iOS / Finder live-reorder
/// pattern: as the cursor enters another chip, the model's `ecosystemOrder`
/// is rewritten on the fly so neighbouring chips slide into their new
/// positions underneath the cursor. The chip being dragged is faded to
/// 0.25 opacity in place, leaving a same-sized ghost slot that moves with
/// the cursor. No separate drop indicator is needed — the faded slot IS
/// the indicator. Dropping commits; the `.move` cursor comes from the
/// delegate returning `DropProposal(operation: .move)` in `dropUpdated`.
struct FilterChipsBar: View {
    @Bindable var model: AppModel

    @State private var draggedItem: Ecosystem?
    /// Only install the mouse-up monitor once per view lifetime — clears
    /// `draggedItem` when the user cancels a drag (drops outside any chip
    /// or presses Esc), so the faded slot doesn't linger.
    @State private var mouseUpMonitorInstalled = false

    private var allOn: Bool {
        model.enabledEcosystems.count == Ecosystem.allCases.count
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                Toggle(isOn: Binding(
                    get: { allOn },
                    set: { _ in toggleAll() }
                )) {
                    Text("All")
                }
                .toggleStyle(.checkbox)

                Divider().frame(height: 16)

                ForEach(model.ecosystemOrder) { eco in
                    EcoCheckbox(ecosystem: eco, model: model)
                        // Fully hide the chip while it's being dragged —
                        // the AppKit drag image already follows the
                        // cursor, so a visible ghost at the slot ends up
                        // doubling it and reading as "two chips". The
                        // empty slot keeps the space reserved and neighbours
                        // slide around it cleanly.
                        .opacity(eco == draggedItem ? 0 : 1)
                        .animation(.easeInOut(duration: 0.18), value: draggedItem)
                        .onDrag {
                            // Defer state mutation off the view-update pass.
                            Task { @MainActor in draggedItem = eco }
                            return NSItemProvider(object: eco.rawValue as NSString)
                        }
                        .onDrop(of: [UTType.plainText], delegate: ChipDropDelegate(
                            target: eco,
                            draggedItem: $draggedItem,
                            onReorder: { source in
                                reorder(source: source, onto: eco)
                            }
                        ))
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .animation(.spring(duration: 0.28, bounce: 0.12), value: model.ecosystemOrder)
        }
        .scrollClipDisabled()
        .onAppear { installMouseUpMonitor() }
    }

    private func toggleAll() {
        if allOn {
            model.enabledEcosystems.removeAll()
        } else {
            model.enabledEcosystems = Set(Ecosystem.allCases)
        }
    }

    /// Live reorder: place `source` at `target`'s current slot. Works in both
    /// directions — the removal shifts the array so the same `insert(at: dstIdx)`
    /// formula lands `source` AFTER `target` when dragging right, BEFORE
    /// when dragging left, without needing branches.
    @MainActor
    private func reorder(source: Ecosystem, onto target: Ecosystem) {
        guard source != target else { return }
        var order = model.ecosystemOrder
        guard let srcIdx = order.firstIndex(of: source),
              let dstIdx = order.firstIndex(of: target) else { return }
        order.remove(at: srcIdx)
        order.insert(source, at: min(dstIdx, order.count))
        model.ecosystemOrder = order
    }

    /// Drag is canceled (drop outside any chip, Esc, mouse released over
    /// a non-drop zone) without triggering `performDrop`. A local
    /// mouse-up monitor is the simplest reliable signal on macOS that the
    /// drag session ended — we just clear `draggedItem` so the faded
    /// chip fades back in.
    private func installMouseUpMonitor() {
        guard !mouseUpMonitorInstalled else { return }
        mouseUpMonitorInstalled = true
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { event in
            if draggedItem != nil {
                DispatchQueue.main.async { draggedItem = nil }
            }
            return event
        }
    }
}

// MARK: - Drop delegate

private struct ChipDropDelegate: DropDelegate {
    let target: Ecosystem
    @Binding var draggedItem: Ecosystem?
    let onReorder: @MainActor (Ecosystem) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [UTType.plainText])
    }

    /// Returning `.move` switches the system drag cursor from the "copy +"
    /// glyph to the plain "move" arrow — we're not duplicating chips.
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    /// Live reorder: as soon as the cursor enters a neighbour chip, move
    /// the dragged chip into that slot. The faded chip then occupies the
    /// new position so the cursor is visually "over" its ghost slot —
    /// which happens to be `target`'s former position.
    func dropEntered(info: DropInfo) {
        guard let source = draggedItem, source != target else { return }
        Task { @MainActor in onReorder(source) }
    }

    /// Order was already updated live during the drag — nothing to do here
    /// but clear the dragged-item state so the chip reappears where it
    /// finally landed.
    func performDrop(info: DropInfo) -> Bool {
        DispatchQueue.main.async { draggedItem = nil }
        return true
    }
}

// MARK: - Checkbox

private struct EcoCheckbox: View {
    let ecosystem: Ecosystem
    @Bindable var model: AppModel

    private var isOn: Binding<Bool> {
        Binding(
            get: { model.enabledEcosystems.contains(ecosystem) },
            set: { on in
                // Option-click → solo this ecosystem; clicking an already-
                // solo'd chip with option held restores the full set.
                // `NSEvent.modifierFlags` reflects the modifier state at
                // the moment the click propagates, which is what we want.
                if NSEvent.modifierFlags.contains(.option) {
                    let all = Set(Ecosystem.allCases)
                    if model.enabledEcosystems == [ecosystem] {
                        model.enabledEcosystems = all
                    } else {
                        model.enabledEcosystems = [ecosystem]
                    }
                    return
                }
                if on { model.enabledEcosystems.insert(ecosystem) }
                else { model.enabledEcosystems.remove(ecosystem) }
            }
        )
    }

    var body: some View {
        // Fixed font weight — toggling between regular/semibold on select
        // caused text to reflow and the bar to jitter.
        Toggle(isOn: isOn) {
            Text(ecosystem.displayName)
                .foregroundStyle(isOn.wrappedValue ? Color.primary : Color.secondary)
        }
        .toggleStyle(.checkbox)
        .tint(ecosystem.tint)
    }
}
