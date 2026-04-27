import SwiftUI
import AppKit

struct MainWindowView: View {
    @Bindable var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // Custom binding: NavigationSplitView wants
        // `NavigationSplitViewVisibility`, the model holds a Bool.
        // Two-way so the OS-side disclosure control and our menu stay
        // in sync — the user can hide via either path and the label
        // flips correctly.
        let sidebarBinding = Binding<NavigationSplitViewVisibility>(
            get: { model.sidebarVisible ? .all : .detailOnly },
            set: { model.sidebarVisible = ($0 != .detailOnly) }
        )
        NavigationSplitView(columnVisibility: sidebarBinding) {
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
        // Confirmation sheet drives off the model so menu commands and
        // the toolbar button trigger the exact same flow. Binding maps
        // `pendingDeletion == nil` ↔ sheet not presented.
        .sheet(isPresented: Binding(
            get: { model.pendingDeletion != nil },
            set: { if !$0 { model.cancelDeletionRequest() } }
        )) {
            let items = model.pendingDeletion ?? []
            ConfirmationSheet(items: items) {
                model.cancelDeletionRequest()
                Task { _ = await model.performDeletion(findings: items) }
            } cancel: {
                model.cancelDeletionRequest()
            }
        }
        .onAppear {
            if model.phase == .idle { model.startScan() }
        }
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
                model.requestDeletionOfSelection()
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
                // Shortcut lives on the menu item (CruftApp commands) so
                // it's discoverable and doesn't double-register here.
                // macOS surfaces the shortcut on hover automatically.
                .help("Scan again")
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
            .help("Group by project or flat")
        }
        .customizationBehavior(.default)

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(id: "trash", placement: .primaryAction) {
            Button {
                model.requestDeletionOfSelection()
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
            .disabled(model.selectedFindings.isEmpty)
            .help("Move selected items to Trash")
        }
        .customizationBehavior(.default)

        ToolbarSpacer(.fixed, placement: .primaryAction)

        ToolbarItem(id: "history", placement: .primaryAction) {
            Button {
                openWindow(id: "history")
            } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            // No `.keyboardShortcut` here — ⌘Y is registered on the
            // History scene itself (see CruftApp), which both auto-creates
            // the Window menu entry and routes the shortcut to opening
            // (or front-bringing) that singleton window.
            .help("Show cleanup history")
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
            .help("Toggle info panel")
        }
        .customizationBehavior(.default)
    }
}

/// Convenience formatter used in a couple of places.
func formatBytes(_ n: Int64) -> String {
    ByteCountFormatter.string(fromByteCount: n, countStyle: .file)
}
