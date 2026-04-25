import SwiftUI
import AppKit

/// Shared row-action helpers used by both the grouped and flat result views,
/// plus the sidebar source rows. Centralizes "Show in Finder", "Copy Path",
/// and "Open in Terminal" so the behavior stays consistent everywhere.
enum FindingActions {

    static func showInFinder(_ paths: [String]) {
        let urls = paths.compactMap { URL(fileURLWithPath: $0) }
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    static func copyPath(_ paths: [String]) {
        let text = paths.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    /// Opens Terminal.app with `cd` into the first path. For multi-selects
    /// we only cd into the first one — spawning many Terminal windows is
    /// hostile. If the path is a file, we open its parent directory.
    static func openInTerminal(_ paths: [String]) {
        guard let first = paths.first else { return }
        var dir = first
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: dir, isDirectory: &isDir),
           !isDir.boolValue {
            dir = (dir as NSString).deletingLastPathComponent
        }
        let url = URL(fileURLWithPath: dir, isDirectory: true)
        let terminalBundleID = "com.apple.Terminal"
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"),
            configuration: NSWorkspace.OpenConfiguration()
        ) { _, _ in }
        _ = terminalBundleID    // reserved if we later switch to launchApplication(withBundleIdentifier:)
    }

    /// Standard four-item context menu for any path-backed row.
    @ViewBuilder
    static func contextButtons(for paths: [String]) -> some View {
        Button("Show in Finder") { showInFinder(paths) }
        Button("Open in Terminal") { openInTerminal(paths) }
        Button("Copy Path") { copyPath(paths) }
    }
}
