import Foundation
import SwiftUI
import Observation
import AppKit

/// Top-level observable app state. One instance injected into the SwiftUI tree.
/// All mutations happen on the main actor; discovery/sizing Tasks are detached
/// and funnel results back via `@MainActor` closures.
@MainActor
@Observable
final class AppModel {

    // MARK: - Scan state

    enum ScanPhase: Equatable {
        case idle
        case discovering        // walker + spotlight running
        case sizing             // discovery done, sizes computing
        case done
    }

    private(set) var phase: ScanPhase = .idle
    private(set) var findings: [Finding] = []
    private(set) var totalFindings: Int = 0
    private(set) var sizedFindings: Int = 0

    /// Total reclaimable bytes across currently-selected, sized items.
    /// Unknown-size items (TBD) don't contribute — they'd inflate the total
    /// without a guarantee of actual reclaim. Respects the active filters:
    /// selections whose rows are currently hidden by filters don't count.
    var reclaimableBytes: Int64 {
        effectiveSelectedFindings.reduce(0) { $0 + $1.reclaimBytes }
    }

    /// Total across all sized items regardless of selection or filters.
    /// Used mid-scan in the status line while "Sizing X of Y" is ticking.
    var scannedBytes: Int64 {
        findings.reduce(0) { $0 + $1.reclaimBytes }
    }

    /// Total across items currently visible under the active filters
    /// (ecosystem chips, depth tier, source toggles, search text). Shown
    /// in the status line once the scan is `done` so the headline size
    /// matches what the user sees in the list.
    var filteredBytes: Int64 {
        filteredFindings.reduce(0) { $0 + $1.reclaimBytes }
    }

    /// Pending-size count — items discovered but not yet sized.
    var pendingSize: Int { findings.filter { $0.size == nil }.count }

    // MARK: - Selection & filters

    var selection: Set<UInt64> = []

    var selectedFindings: [Finding] {
        findings.filter { selection.contains($0.id) }
    }

    /// Items that are both selected AND currently visible under the active
    /// filters. This is what Delete acts on and what the status line / info
    /// panel summary report. Selections whose rows are hidden by filters
    /// (ecosystem chips, depth tier, source toggles, search) stay warm in
    /// `selection` — flipping a filter back on reveals them selected — but
    /// they don't silently get deleted and don't inflate the reclaim total.
    var effectiveSelectedFindings: [Finding] {
        filteredFindings.filter { selection.contains($0.id) }
    }

    var filterTier: RegenEffort = .low
    var enabledEcosystems: Set<Ecosystem> = Set(Ecosystem.allCases)
    var searchText: String = ""
    var useProjectGrouping: Bool = true

    /// Display order of the ecosystem filter chips. Drag to reorder in the
    /// filter bar; persists across launches. New ecosystems appended in a
    /// future release are merged in at the end automatically.
    var ecosystemOrder: [Ecosystem] = AppModel.loadEcosystemOrder() {
        didSet {
            if let data = try? JSONEncoder().encode(ecosystemOrder) {
                UserDefaults.standard.set(data, forKey: Self.ecosystemOrderKey)
            }
        }
    }

    // MARK: - Configuration

    var scanRoots: [ScanRoot] = AppModel.loadScanRoots()
    var spotlightEnabled: Bool = AppModel.loadSpotlightEnabled() {
        didSet {
            UserDefaults.standard.set(spotlightEnabled, forKey: Self.spotlightKey)
            // Pure display filter — no rescan. Spotlight always runs at scan
            // time so toggling on later reveals the cached results instantly.
        }
    }
    var globalCachesEnabled: Bool = AppModel.loadGlobalCachesEnabled() {
        didSet {
            UserDefaults.standard.set(globalCachesEnabled, forKey: Self.globalCachesKey)
        }
    }
    var systemCachesEnabled: Bool = AppModel.loadSystemCachesEnabled() {
        didSet {
            UserDefaults.standard.set(systemCachesEnabled, forKey: Self.systemCachesKey)
        }
    }
    var infoPanelVisible: Bool = AppModel.loadInfoPanelVisible() {
        didSet {
            UserDefaults.standard.set(infoPanelVisible, forKey: Self.infoPanelKey)
        }
    }
    let rules: [Rule] = RuleCatalog.rules
    private let history = HistoryStore()

    /// Mirror of the history actor's contents, kept on the main actor so
    /// the History window can bind to it directly. Refreshed at startup
    /// and after every successful deletion.
    private(set) var historyEntries: [HistoryEntry] = []

    private static let scanRootsKey = "regen.scanRoots.v1"
    private static let spotlightKey = "regen.spotlightEnabled.v1"
    private static let globalCachesKey = "regen.globalCachesEnabled.v1"
    private static let systemCachesKey = "regen.systemCachesEnabled.v1"
    private static let infoPanelKey = "regen.infoPanelVisible.v1"
    private static let ecosystemOrderKey = "regen.ecosystemOrder.v1"

    private static func loadScanRoots() -> [ScanRoot] {
        if let data = UserDefaults.standard.data(forKey: scanRootsKey),
           let roots = try? JSONDecoder().decode([ScanRoot].self, from: data),
           !roots.isEmpty {
            return roots
        }
        return ScanRoot.defaults()
    }

    private static func loadSpotlightEnabled() -> Bool {
        // Off by default on first run — it scans home-wide and can be slow
        // and surprising. Users can opt in from the sidebar.
        guard UserDefaults.standard.object(forKey: spotlightKey) != nil else { return false }
        return UserDefaults.standard.bool(forKey: spotlightKey)
    }

    private static func loadGlobalCachesEnabled() -> Bool {
        guard UserDefaults.standard.object(forKey: globalCachesKey) != nil else { return true }
        return UserDefaults.standard.bool(forKey: globalCachesKey)
    }

    private static func loadSystemCachesEnabled() -> Bool {
        guard UserDefaults.standard.object(forKey: systemCachesKey) != nil else { return true }
        return UserDefaults.standard.bool(forKey: systemCachesKey)
    }

    /// Load the persisted ecosystem order, merging in any ecosystem cases
    /// that didn't exist when the order was last saved (so a future
    /// release adding `.kotlin` doesn't silently drop it). Unknown cases
    /// from a downgrade are ignored.
    private static func loadEcosystemOrder() -> [Ecosystem] {
        let defaults = Ecosystem.allCases
        guard let data = UserDefaults.standard.data(forKey: ecosystemOrderKey),
              let saved = try? JSONDecoder().decode([Ecosystem].self, from: data)
        else {
            return defaults
        }
        let savedSet = Set(saved)
        let missing = defaults.filter { !savedSet.contains($0) }
        return saved + missing
    }

    private static func loadInfoPanelVisible() -> Bool {
        // Default off — panel content is still being populated; users can
        // opt in via the toolbar button.
        guard UserDefaults.standard.object(forKey: infoPanelKey) != nil else { return false }
        return UserDefaults.standard.bool(forKey: infoPanelKey)
    }

    /// Persist the current scan roots and kick off a fresh scan.
    func updateScanRoots(_ newRoots: [ScanRoot]) {
        scanRoots = newRoots
        if let data = try? JSONEncoder().encode(newRoots) {
            UserDefaults.standard.set(data, forKey: Self.scanRootsKey)
        }
        startScan()
    }

    /// Toggle enabled state for a given root. Pure display filter — no rescan.
    func setRootEnabled(_ path: String, enabled: Bool) {
        if let idx = scanRoots.firstIndex(where: { $0.path == path }) {
            scanRoots[idx].enabled = enabled
            if let data = try? JSONEncoder().encode(scanRoots) {
                UserDefaults.standard.set(data, forKey: Self.scanRootsKey)
            }
        }
    }

    // MARK: - Tasks

    private var scanTask: Task<Void, Never>?
    private var deletionTask: Task<Void, Never>?

    // MARK: - Startup

    init() {
        // Warm the history mirror so the History window opens with data
        // even before the user has triggered a deletion this session.
        Task { @MainActor in
            self.historyEntries = await self.history.load()
        }
    }

    // MARK: - History

    func clearHistory() {
        Task { @MainActor in
            await self.history.clear()
            self.historyEntries = []
        }
    }

    private func refreshHistoryMirror() async {
        let snapshot = await history.load()
        await MainActor.run { self.historyEntries = snapshot }
    }

    // MARK: - Derived views

    /// Findings after filters applied, sorted by size descending.
    var filteredFindings: [Finding] {
        let text = searchText.lowercased()
        return findings.filter { f in
            guard sourceIsEnabled(f) else { return false }
            guard f.tier <= filterTier else { return false }
            guard enabledEcosystems.contains(f.ecosystem) else { return false }
            if !text.isEmpty,
               !f.presentationPath.lowercased().contains(text),
               !(f.projectName?.lowercased().contains(text) ?? false) {
                return false
            }
            return true
        }.sorted { ($0.size ?? 0) > ($1.size ?? 0) }
    }

    /// True if the source (scan root, Spotlight, or global caches) that
    /// produced this finding is currently enabled in the sidebar.
    private func sourceIsEnabled(_ f: Finding) -> Bool {
        if f.fromSpotlight { return spotlightEnabled }
        guard let project = f.projectPath else {
            // Global cache — split by user-home vs system-owned.
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            if f.presentationPath == home || f.presentationPath.hasPrefix(home + "/") {
                return globalCachesEnabled
            }
            return systemCachesEnabled
        }
        for root in scanRoots {
            let rootPath = root.url.path
            if project == rootPath || project.hasPrefix(rootPath + "/") {
                return root.enabled
            }
        }
        return true
    }

    var projectGroups: [ProjectGroup] {
        filteredFindings.groupedByProject()
    }

    // MARK: - Scanning

    func startScan() {
        cancelScan()
        findings.removeAll(keepingCapacity: true)
        selection.removeAll()
        totalFindings = 0
        sizedFindings = 0
        phase = .discovering

        // Scan covers ALL configured roots + Spotlight regardless of their
        // enabled flags — toggling enabled is purely a display filter so the
        // user gets instant hide/show without waiting on a rescan.
        let coord = DiscoveryCoordinator(
            rules: rules,
            scanRoots: scanRoots.compactMap { $0.exists ? $0.url : nil },
            spotlightEnabled: true
        )
        // A fresh inode registry per scan — carrying one across scans makes
        // the sizer skip every inode on the second run and report 0 KB.
        let sizer = Sizer(registry: InodeRegistry())
        let sink = StreamSink()
        scanTask = Task { [weak self] in
            guard let self else { return }
            // Snapshot the history index once up front. Each finding gets
            // tagged with its previous cleanup date (if any) before reaching
            // the main actor, so the UI can show "Cleaned 4d ago" without
            // re-entering the actor per row.
            let cleanedIndex = await self.history.lastCleanedIndex()

            // 1. Discovery
            var pending: [Finding] = []
            var lastFlush = ContinuousClock.now
            for await finding in coord.stream() {
                if Task.isCancelled { return }
                var enriched = finding
                enriched.lastCleanedAt = cleanedIndex[finding.presentationPath]
                pending.append(enriched)
                let now = ContinuousClock.now
                if pending.count >= 25 || now - lastFlush > .milliseconds(120) {
                    let batch = pending; pending.removeAll(keepingCapacity: true)
                    lastFlush = now
                    await MainActor.run { self.ingest(batch) }
                }
            }
            if !pending.isEmpty {
                let final = pending
                await MainActor.run { self.ingest(final) }
            }

            // 2. Sizing — kick off a bounded TaskGroup
            await MainActor.run { self.phase = .sizing }
            let snapshot = self.findings
            await withTaskGroup(of: (UInt64, Int64).self) { group in
                var launched = 0
                let maxConcurrent = min(ProcessInfo.processInfo.activeProcessorCount / 2, 6)
                var iterator = snapshot.makeIterator()

                func sizeTask(for f: Finding) -> @Sendable () async -> (UInt64, Int64) {
                    let id = f.id
                    // If the rule defines a custom sizer (e.g. `brew cleanup
                    // --dry-run`), use it instead of the directory walker.
                    if let rule = RuleCatalog.rule(id: f.ruleId),
                       let custom = rule.customSizer {
                        return {
                            let s = await CustomSizerRunner.run(custom)
                            return (id, s)
                        }
                    }
                    let url = URL(fileURLWithPath: f.presentationPath)
                    return {
                        let s = await sizer.size(of: url)
                        return (id, s)
                    }
                }

                while launched < maxConcurrent, let f = iterator.next() {
                    group.addTask(operation: sizeTask(for: f))
                    launched += 1
                }

                while let (id, bytes) = await group.next() {
                    if Task.isCancelled { return }
                    await MainActor.run { self.updateSize(id: id, bytes: bytes) }
                    if let f = iterator.next() {
                        group.addTask(operation: sizeTask(for: f))
                    }
                }
            }

            await MainActor.run { self.phase = .done }
            _ = sink       // keep alive
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        if phase != .idle { phase = .done }
    }

    // MARK: - Ingest helpers (main actor)

    private func ingest(_ batch: [Finding]) {
        findings.append(contentsOf: batch)
        totalFindings = findings.count
        // No auto-select — the user chooses what to reclaim. Predictable wins
        // over aggressive.
    }

    // MARK: - Selection helpers

    func selectAllVisible() {
        selection = Set(filteredFindings.map(\.id))
    }

    func deselectAll() {
        selection.removeAll()
    }

    private func updateSize(id: UInt64, bytes: Int64) {
        guard let idx = findings.firstIndex(where: { $0.id == id }) else { return }
        findings[idx].size = bytes
        sizedFindings += 1
    }

    // MARK: - Deletion

    func performDeletion(findings: [Finding]) async -> DeletionSummary {
        let deleter = Deleter(history: history)
        var reclaimed: Int64 = 0
        var ok = 0
        var errors: [(Finding, String)] = []
        var trashed: [HistoryEntry] = []

        for await event in deleter.delete(findings) {
            switch event {
            case .started: break
            case .finishedItem(let f, let success, let error):
                if success {
                    ok += 1
                    reclaimed += f.size ?? 0
                    // Remove from model immediately.
                    self.findings.removeAll { $0.id == f.id }
                    self.selection.remove(f.id)
                } else if let error {
                    errors.append((f, error))
                }
            case .finishedAll(let r, let entries):
                reclaimed = r
                trashed = entries
            }
        }
        // Refresh the History window's mirror so it reflects this batch
        // without needing a window close/reopen.
        await refreshHistoryMirror()
        return DeletionSummary(
            reclaimed: reclaimed,
            successCount: ok,
            errors: errors,
            entries: trashed
        )
    }
}

struct DeletionSummary: Sendable {
    let reclaimed: Int64
    let successCount: Int
    let errors: [(Finding, String)]
    let entries: [HistoryEntry]
}

/// Dummy holder so the detached task keeps its closures in scope.
private final class StreamSink: @unchecked Sendable {}
