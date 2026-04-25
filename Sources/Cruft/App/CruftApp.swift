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
    }
}
