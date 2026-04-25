import SwiftUI
import AppKit

struct MainWindowView: View {
    @Bindable var model: AppModel
    @State private var showConfirm = false
    @State private var pendingItems: [Finding] = []

    private func requestConfirm() {
        // Delete only acts on items that are currently visible — selections
        // hidden by filters stay in the selection set but don't go to Trash.
        let sel = model.effectiveSelectedFindings
        guard !sel.isEmpty else { return }
        pendingItems = sel
        showConfirm = true
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
        } detail: {
            detailPane
                .toolbar(id: "main") { toolbar }
                .navigationTitle("")
                .inspector(isPresented: $model.infoPanelVisible) {
                    InfoPanelView(model: model)
                        .inspectorColumnWidth(min: 260, ideal: 300, max: 420)
                }
        }
        // macOS convention: toolbar search field sits at the trailing edge
        // of the toolbar and gets standard ⌘F focus / clear-button behavior.
        // Other primary actions (trash, info toggle) sit to its left.
        .searchable(text: $model.searchText,
                    placement: .toolbar,
                    prompt: "Search paths or projects")
        .sheet(isPresented: $showConfirm) {
            let items = pendingItems.isEmpty ? model.selectedFindings : pendingItems
            ConfirmationSheet(items: items) {
                showConfirm = false
                Task { _ = await model.performDeletion(findings: items) }
            } cancel: {
                showConfirm = false
            }
        }
        .background { keyboardShortcuts }
        .onAppear {
            if model.phase == .idle { model.startScan() }
        }
    }

    /// Zero-size buttons that register keyboard shortcuts without taking
    /// visible space. Clean way to attach global shortcuts when the visible
    /// controls (Picker, etc.) can't carry `.keyboardShortcut` directly.
    private var keyboardShortcuts: some View {
        ZStack {
            Button("By Project") {
                model.useProjectGrouping = true
            }
            .keyboardShortcut("1", modifiers: .command)

            Button("Flat") {
                model.useProjectGrouping = false
            }
            .keyboardShortcut("2", modifiers: .command)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private var detailPane: some View {
        VStack(spacing: 0) {
            ResultsTable(model: model)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Floating filter bar at the top of the list — sits on a
                // glass material so list rows blur as they scroll behind it,
                // matching Finder's toolbar-under-scroll behavior.
                .safeAreaInset(edge: .top, spacing: 0) {
                    FilterChipsBar(model: model)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.regularMaterial)
                        .overlay(
                            Rectangle()
                                .frame(height: 0.5)
                                .foregroundStyle(.separator),
                            alignment: .bottom
                        )
                }

            StatusLine(model: model) {
                requestConfirm()
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some CustomizableToolbarContent {
        ToolbarItem(id: "scan", placement: .navigation) {
            if model.phase == .discovering || model.phase == .sizing {
                Button {
                    model.cancelScan()
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .help("Stop scanning")
            } else {
                Button {
                    model.startScan()
                } label: {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .help("Scan again (⌘R)")
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
        .customizationBehavior(.default)

        ToolbarSpacer(.fixed, placement: .navigation)

        ToolbarItem(id: "view-mode", placement: .automatic) {
            Picker("View", selection: $model.useProjectGrouping) {
                Label("By Project", systemImage: "text.below.folder").tag(true)
                Label("Flat", systemImage: "list.bullet").tag(false)
            }
            .pickerStyle(.segmented)
            .labelStyle(.iconOnly)
            .help("Group by project (⌘1) or flat view (⌘2)")
        }
        .customizationBehavior(.default)

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(id: "trash", placement: .primaryAction) {
            Button {
                requestConfirm()
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
            .disabled(model.selectedFindings.isEmpty)
            .help("Move selected items to Trash (⌘⌫)")
            .keyboardShortcut(.delete, modifiers: [.command])
        }
        .customizationBehavior(.default)

        ToolbarSpacer(.fixed, placement: .primaryAction)

        // Info panel toggle sits LEFT of the searchable-injected search
        // field, matching macOS convention (search always anchors to the
        // toolbar's trailing edge).
        ToolbarItem(id: "info", placement: .primaryAction) {
            Button {
                model.infoPanelVisible.toggle()
            } label: {
                Label("Info", systemImage: "sidebar.trailing")
            }
            .help("Toggle info panel (⌘⌥I)")
            .keyboardShortcut("i", modifiers: [.command, .option])
        }
        .customizationBehavior(.default)
    }
}

/// Convenience formatter used in a couple of places.
func formatBytes(_ n: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: n, countStyle: .file)
}
