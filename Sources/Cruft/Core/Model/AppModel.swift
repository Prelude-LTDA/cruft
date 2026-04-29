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
    /// Per-app Darwin-cache subdirs (one finding per bundle's
    /// `com.apple.metal/` etc.). Off by default — these are usually a
    /// long tail of sub-MB caches that would dominate the default scan.
    var perAppCachesEnabled: Bool = AppModel.loadPerAppCachesEnabled() {
        didSet {
            UserDefaults.standard.set(perAppCachesEnabled, forKey: Self.perAppCachesKey)
        }
    }
    var infoPanelVisible: Bool = AppModel.loadInfoPanelVisible() {
        didSet {
            UserDefaults.standard.set(infoPanelVisible, forKey: Self.infoPanelKey)
        }
    }
    /// Sidebar (sources list) visibility. Drives the column-visibility
    /// binding on `NavigationSplitView`, so the OS-side disclosure
    /// triangle and our menu command stay in sync. Persists across
    /// launches like the other panel toggles.
    var sidebarVisible: Bool = AppModel.loadSidebarVisible() {
        didSet {
            UserDefaults.standard.set(sidebarVisible, forKey: Self.sidebarKey)
        }
    }
    /// Whether the user has dismissed the "Where does your code live?"
    /// empty-state callout shown in the sidebar when no scan roots exist.
    /// Once dismissed, the sidebar falls back to a quiet borderless
    /// "Add Folder…" link so we don't keep nagging — the user has signaled
    /// they know how to add a folder. Persists across launches; never
    /// auto-resets, even if the user later adds and then removes all roots.
    var emptyScanRootsCalloutDismissed: Bool = AppModel.loadEmptyScanRootsCalloutDismissed() {
        didSet {
            UserDefaults.standard.set(emptyScanRootsCalloutDismissed, forKey: Self.emptyScanRootsCalloutDismissedKey)
        }
    }
    let rules: [Rule] = RuleCatalog.rules
    private let history = HistoryStore()

    /// Mirror of the history actor's contents, kept on the main actor so
    /// the History window can bind to it directly. Refreshed at startup
    /// and after every successful deletion.
    private(set) var historyEntries: [HistoryEntry] = []

    /// Items currently awaiting confirmation in the deletion sheet, or nil
    /// when no sheet is up. Lives on the model (not a view) so menu
    /// commands and the toolbar button drive the exact same flow.
    var pendingDeletion: [Finding]? = nil

    /// Snapshot the visible selection and surface the confirmation sheet.
    /// Selections hidden by filters stay in `selection` but don't go into
    /// the sheet, mirroring `effectiveSelectedFindings`.
    func requestDeletionOfSelection() {
        let sel = effectiveSelectedFindings
        guard !sel.isEmpty else { return }
        pendingDeletion = sel
    }

    func cancelDeletionRequest() {
        pendingDeletion = nil
    }

    private static let scanRootsKey = "regen.scanRoots.v1"
    private static let spotlightKey = "regen.spotlightEnabled.v1"
    private static let globalCachesKey = "regen.globalCachesEnabled.v1"
    private static let systemCachesKey = "regen.systemCachesEnabled.v1"
    private static let perAppCachesKey = "regen.perAppCachesEnabled.v1"
    private static let infoPanelKey = "regen.infoPanelVisible.v1"
    private static let sidebarKey = "regen.sidebarVisible.v1"
    private static let emptyScanRootsCalloutDismissedKey = "regen.emptyScanRootsCalloutDismissed.v1"
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

    private static func loadPerAppCachesEnabled() -> Bool {
        // Default off — per-app shader caches are noisy (250+ rows on a
        // typical machine) and the long tail is sub-MB. Users opt in via
        // the sidebar when they want to clean those up.
        guard UserDefaults.standard.object(forKey: perAppCachesKey) != nil else { return false }
        return UserDefaults.standard.bool(forKey: perAppCachesKey)
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
        // Default on — the breakdown bar and selection details give a
        // first-time user something to look at while the initial scan
        // populates the list. Users can hide via the toolbar button or
        // the View menu.
        guard UserDefaults.standard.object(forKey: infoPanelKey) != nil else { return true }
        return UserDefaults.standard.bool(forKey: infoPanelKey)
    }

    private static func loadEmptyScanRootsCalloutDismissed() -> Bool {
        // Default false — show the callout on first launch when no scan
        // roots are detected. `bool(forKey:)` returns false when the key
        // is unset, which is exactly what we want here.
        return UserDefaults.standard.bool(forKey: emptyScanRootsCalloutDismissedKey)
    }

    private static func loadSidebarVisible() -> Bool {
        // Default on — the sidebar is the primary configuration surface
        // (scan roots + source toggles).
        guard UserDefaults.standard.object(forKey: sidebarKey) != nil else { return true }
        return UserDefaults.standard.bool(forKey: sidebarKey)
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

    // MARK: - Sources solo (option-click)

    /// Identifies one of the checkboxes in the sidebar's Sources section.
    /// Used by the option-click "solo this source" handler so the same
    /// pattern works uniformly across the global toggles, individual scan
    /// roots, and Spotlight.
    enum SourceID: Equatable, Hashable {
        case system, perApp, globalUser, spotlight
        case scanRoot(path: String)
    }

    /// Whether the given source is currently the *only* enabled one across
    /// the entire Sources section. Drives the option-click toggle: if
    /// already solo'd, option-click restores everything; otherwise it
    /// solos this one.
    func isOnlySource(_ id: SourceID) -> Bool {
        let states = sourceStates()
        return states[id] == true && states.values.filter { $0 }.count == 1
    }

    /// Solo a single source — set it on, everything else off. Mirrors
    /// `EcoCheckbox`'s option-click behavior in FilterChipsBar.
    func soloSource(_ id: SourceID) {
        systemCachesEnabled = (id == .system)
        perAppCachesEnabled = (id == .perApp)
        globalCachesEnabled = (id == .globalUser)
        spotlightEnabled = (id == .spotlight)
        var roots = scanRoots
        for i in roots.indices {
            roots[i].enabled = (.scanRoot(path: roots[i].path) == id)
        }
        scanRoots = roots
        persistScanRootsEnabledStates()
    }

    /// Re-enable every source (the "restore from solo" action).
    func enableAllSources() {
        systemCachesEnabled = true
        perAppCachesEnabled = true
        globalCachesEnabled = true
        spotlightEnabled = true
        var roots = scanRoots
        for i in roots.indices {
            roots[i].enabled = true
        }
        scanRoots = roots
        persistScanRootsEnabledStates()
    }

    private func sourceStates() -> [SourceID: Bool] {
        var s: [SourceID: Bool] = [
            .system: systemCachesEnabled,
            .perApp: perAppCachesEnabled,
            .globalUser: globalCachesEnabled,
            .spotlight: spotlightEnabled,
        ]
        for r in scanRoots {
            s[.scanRoot(path: r.path)] = r.enabled
        }
        return s
    }

    private func persistScanRootsEnabledStates() {
        if let data = try? JSONEncoder().encode(scanRoots) {
            UserDefaults.standard.set(data, forKey: Self.scanRootsKey)
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
        }.sorted { a, b in
            // Stable secondary key on `id` — Swift's `sorted` is not
            // stable, so without a tie-breaker, items of equal size
            // shuffle on every re-sort (visible during scan as rows
            // reorder under the cursor).
            let sa = a.size ?? 0
            let sb = b.size ?? 0
            if sa != sb { return sa > sb }
            return a.id < b.id
        }
    }

    /// True if the source (scan root, Spotlight, or global caches) that
    /// produced this finding is currently enabled in the sidebar.
    private func sourceIsEnabled(_ f: Finding) -> Bool {
        if f.fromSpotlight { return spotlightEnabled }
        // Per-app Darwin-cache rules (one finding per bundle's
        // `com.apple.metal/` etc.) are gated by their own toggle so the
        // long tail doesn't dominate the default scan.
        if RuleCatalog.rule(id: f.ruleId)?.scope == .perAppCache {
            return perAppCachesEnabled
        }
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
                // ~1 Hz cadence (or sooner if a burst hits 250 items).
                // Faster updates make the list visibly jitter and force
                // SwiftUI to re-evaluate the menu bar mid-render — the
                // Window menu and View > Full Screen items glitch when
                // observed properties (`findings.isEmpty`, etc.) change
                // while a menu is open.
                if pending.count >= 250 || now - lastFlush > .milliseconds(1000) {
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

                // Sizing-side analogue of the discovery flush. Without this,
                // each completed sizer task fires `updateSize` directly on the
                // main actor — hundreds of mutations per second through a
                // chain that re-derives `filteredFindings` / `projectGroups`
                // and ripples into the sidebar + menu bar evaluation.
                var pendingSizes: [(UInt64, Int64)] = []
                var lastSizeFlush = ContinuousClock.now
                while let (id, bytes) = await group.next() {
                    if Task.isCancelled { return }
                    pendingSizes.append((id, bytes))
                    let now = ContinuousClock.now
                    if pendingSizes.count >= 250 || now - lastSizeFlush > .milliseconds(1000) {
                        let batch = pendingSizes
                        pendingSizes.removeAll(keepingCapacity: true)
                        lastSizeFlush = now
                        await MainActor.run { self.updateSizes(batch) }
                    }
                    if let f = iterator.next() {
                        group.addTask(operation: sizeTask(for: f))
                    }
                }
                if !pendingSizes.isEmpty {
                    let final = pendingSizes
                    await MainActor.run { self.updateSizes(final) }
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

    // Select All is handled by the system Edit > Select All command,
    // which routes through `selectAll:` on the responder chain — Table
    // and List implement it natively against the selection binding. We
    // only own Deselect, since "select none" isn't a system standard.

    func deselectAll() {
        selection.removeAll()
    }

    /// Apply a batch of (id, sizeBytes) updates in a single pass. One
    /// `findings` mutation regardless of batch length, so SwiftUI's
    /// observation cascade only fires once per flush.
    private func updateSizes(_ batch: [(UInt64, Int64)]) {
        guard !batch.isEmpty else { return }
        let sizesByID = Dictionary(uniqueKeysWithValues: batch)
        var sized = 0
        for idx in findings.indices {
            if let bytes = sizesByID[findings[idx].id] {
                findings[idx].size = bytes
                sized += 1
            }
        }
        sizedFindings += sized
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
