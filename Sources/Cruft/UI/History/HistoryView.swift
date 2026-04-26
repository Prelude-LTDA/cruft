import SwiftUI

/// Audit log of every cleanup ever performed by Cruft. Lives in its own
/// singleton `Window` scene (id `"history"`), opened via ⌘Y or the
/// toolbar clock button. Read-only — entries can only be wiped wholesale
/// via the "Clear History" toolbar button.
struct HistoryView: View {
    @Bindable var model: AppModel

    @State private var sortOrder: [KeyPathComparator<HistoryEntry>] = [
        KeyPathComparator(\.timestamp, order: .reverse)
    ]
    @State private var selection: Set<HistoryEntry.ID> = []
    @State private var searchText = ""
    @State private var showClearConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            if model.historyEntries.isEmpty {
                emptyState
            } else {
                table
                footer
            }
        }
        .navigationTitle("Cleanup History")
        .searchable(text: $searchText,
                    placement: .toolbar,
                    prompt: "Search paths or rules")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    // `clear` (the keyboard backspace glyph) instead of
                    // `trash` to disambiguate from the main window's
                    // Move-to-Trash button — these do very different
                    // things (wipe a record vs. send files to the bin).
                    Label("Clear History", systemImage: "clear")
                }
                .disabled(model.historyEntries.isEmpty)
                .help("Wipe every recorded cleanup. Doesn't affect files on disk.")
            }
        }
        .confirmationDialog(
            "Clear all cleanup history?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear", role: .destructive) {
                model.clearHistory()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let n = model.historyEntries.count
            Text("This permanently deletes the record of \(n) cleanup\(n == 1 ? "" : "s"). It does not affect any files — those are already in Trash or were removed by a clean command.")
        }
    }

    // MARK: - Pieces

    private var table: some View {
        Table(visibleEntries, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Date", value: \.timestamp) { entry in
                Text(DateDisplay.relativeText(entry.timestamp))
                    .help(DateDisplay.absoluteText(entry.timestamp))
            }
            .width(min: 100, ideal: 130)

            TableColumn("Path", value: \.path) { entry in
                Text(displayPath(entry.path))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(entry.path)
            }
            .width(min: 200, ideal: 420)

            TableColumn("Rule", value: \.ruleId) { entry in
                Text(RuleCatalog.rule(id: entry.ruleId)?.displayName ?? entry.ruleId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(min: 100, ideal: 180)

            TableColumn("Method", value: \.methodSortKey) { entry in
                Text(entry.method.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(min: 70, ideal: 90)

            TableColumn("Size", value: \.sizeBytes) { entry in
                HStack {
                    Spacer(minLength: 0)
                    Text(ByteCountFormatter.string(fromByteCount: entry.sizeBytes, countStyle: .file))
                        .monospacedDigit()
                }
            }
            .width(min: 70, ideal: 100)
        }
        .contextMenu(forSelectionType: HistoryEntry.ID.self) { ids in
            // Single context-menu action for now — show the trashed copy
            // in Finder if it's still there. Restoration is left to the
            // user via Finder's Put Back.
            Button("Show Trashed Item in Finder") {
                showTrashedInFinder(ids: ids)
            }
            .disabled(!ids.contains { trashedURLForVisible($0) != nil })
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No cleanups recorded yet.")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Once you clean items, they'll show up here.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(summaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    // MARK: - Derivations

    private var visibleEntries: [HistoryEntry] {
        let filtered: [HistoryEntry]
        if searchText.isEmpty {
            filtered = model.historyEntries
        } else {
            let needle = searchText.lowercased()
            filtered = model.historyEntries.filter { entry in
                if entry.path.lowercased().contains(needle) { return true }
                if entry.ruleId.lowercased().contains(needle) { return true }
                if let name = RuleCatalog.rule(id: entry.ruleId)?.displayName,
                   name.lowercased().contains(needle) { return true }
                return false
            }
        }
        return filtered.sorted(using: sortOrder)
    }

    private var summaryText: String {
        let visible = visibleEntries
        let totalSize = visible.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let count = visible.count
        let prefix = "\(count) cleanup\(count == 1 ? "" : "s")"
        let size = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        if count == model.historyEntries.count {
            return "\(prefix) · \(size) reclaimed"
        }
        return "\(prefix) of \(model.historyEntries.count) shown · \(size) reclaimed"
    }

    private func displayPath(_ path: String) -> String {
        (path as NSString).abbreviatingWithTildeInPath
    }

    private func trashedURLForVisible(_ id: HistoryEntry.ID) -> URL? {
        guard let entry = visibleEntries.first(where: { $0.id == id }),
              let trashed = entry.trashedTo else { return nil }
        let url = URL(fileURLWithPath: trashed)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func showTrashedInFinder(ids: Set<HistoryEntry.ID>) {
        let urls = ids.compactMap { trashedURLForVisible($0) }
        guard !urls.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }
}
