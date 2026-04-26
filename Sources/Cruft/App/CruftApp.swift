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
            CommandGroup(after: .appInfo) {
                Button("Scan Now") { model.startScan() }
                    .keyboardShortcut("r", modifiers: [.command])
            }
            // Select All / Deselect All appended to Edit so they work from
            // anywhere in the window without focus juggling.
            CommandGroup(after: .pasteboard) {
                Divider()
                Button("Select All") { model.selectAllVisible() }
                    .keyboardShortcut("a", modifiers: [.command])
                    .disabled(model.findings.isEmpty)
                Button("Deselect All") { model.deselectAll() }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    .disabled(model.selection.isEmpty)
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
