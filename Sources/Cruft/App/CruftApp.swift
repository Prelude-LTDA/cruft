import SwiftUI
import AppKit

@main
struct CruftApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        Window("Cruft", id: "main") {
            MainWindowView(model: model)
                .frame(minWidth: 980, idealWidth: 1200,
                       minHeight: 620, idealHeight: 780)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {} // no "New Window"
            // macOS 26 renders SF Symbols next to menu text when the
            // Button's label is a `Label`. Icons mirror the toolbar
            // glyphs for the same actions where one exists, so the
            // visual vocabulary stays consistent across menus and chrome.
            CommandGroup(after: .appInfo) {
                Button { model.startScan() } label: {
                    Label("Scan Now", systemImage: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
            // Deselect All + Move to Trash appended to Edit. We deliberately
            // don't add our own Select All here — the system already provides
            // one in the .pasteboard group, and SwiftUI's Table/List route
            // its responder action (selectAll:) into the selection binding,
            // so ⌘A Just Works while also picking up focus-aware behavior
            // for free (⌘A in the search field selects text, ⌘A in the
            // results selects rows).
            CommandGroup(after: .pasteboard) {
                Divider()
                Button { model.deselectAll() } label: {
                    // Outline version of the StatusLine's clear-selection
                    // glyph (`xmark.circle.fill`) — same family, sized for
                    // the menu's lighter-weight context.
                    Label("Deselect All", systemImage: "xmark.circle")
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                .disabled(model.selection.isEmpty)
                Divider()
                Button { model.requestDeletionOfSelection() } label: {
                    Label("Move to Trash", systemImage: "trash")
                }
                .keyboardShortcut(.delete, modifiers: [.command])
                .disabled(model.effectiveSelectedFindings.isEmpty)
            }
            // View menu: view-mode picker, then both panel toggles
            // grouped together at the bottom (consistent vocabulary —
            // both flip Show/Hide labels with state, both use the
            // matching `sidebar.*` glyph).
            CommandGroup(after: .sidebar) {
                Divider()
                Button { model.useProjectGrouping = true } label: {
                    Label("By Project", systemImage: "text.below.folder")
                }
                .keyboardShortcut("1", modifiers: [.command])
                Button { model.useProjectGrouping = false } label: {
                    Label("Flat", systemImage: "list.bullet")
                }
                .keyboardShortcut("2", modifiers: [.command])
                Divider()
                Button {
                    // `withAnimation` is required for NavigationSplitView's
                    // columnVisibility binding to animate — without it,
                    // programmatic flips snap. AppKit's toggleSidebar:
                    // animates internally; the SwiftUI-binding path doesn't.
                    withAnimation { model.sidebarVisible.toggle() }
                } label: {
                    Label(model.sidebarVisible ? "Hide Sidebar" : "Show Sidebar",
                          systemImage: "sidebar.leading")
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
                Button { model.infoPanelVisible.toggle() } label: {
                    Label(model.infoPanelVisible ? "Hide Info Panel" : "Show Info Panel",
                          systemImage: "sidebar.trailing")
                }
                .keyboardShortcut("i", modifiers: [.command, .option])
            }
        }

        // Singleton history window. `Window` (vs `WindowGroup`) only ever
        // has one instance — opening it again brings the existing one
        // forward instead of stacking duplicates. Matches Safari ⌘Y.
        Window("Cleanup History", id: "history") {
            HistoryView(model: model)
                .frame(minWidth: 720, idealWidth: 1180,
                       minHeight: 420, idealHeight: 600)
        }
        .windowToolbarStyle(.unified(showsTitle: true))
        // Sized to fit all five columns at their ideal widths (Date 130 +
        // Path 420 + Rule 180 + Method 90 + Size 100 = 920) with room for
        // the table chrome and a generous Path column.
        .defaultSize(width: 1180, height: 600)
        .keyboardShortcut("y", modifiers: [.command])
    }
}
