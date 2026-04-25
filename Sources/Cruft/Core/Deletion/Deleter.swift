import Foundation
import AppKit

/// Single entrypoint for deletion. Never hard-removes — only Trash or a known
/// clean command. Emits events so the UI can show progress and update totals.
enum DeletionEvent: Sendable {
    case started(total: Int)
    case finishedItem(finding: Finding, success: Bool, error: String?)
    case finishedAll(reclaimed: Int64, entries: [HistoryEntry])
}

struct Deleter {
    let history: HistoryStore

    /// Execute deletion for a set of findings. Returns an AsyncStream of events.
    ///
    /// Trashables are handed to `NSWorkspace.recycle` as a single batch so the
    /// user gets the proper Finder animation and the system trash sound (one
    /// `NSWorkspace` call = one sound + one animation). Clean-command items
    /// run sequentially after.
    func delete(_ findings: [Finding]) -> AsyncStream<DeletionEvent> {
        AsyncStream { continuation in
            Task {
                continuation.yield(.started(total: findings.count))
                var reclaimed: Int64 = 0
                var entries: [HistoryEntry] = []

                let (trashables, cleanables, sudoables) = Self.partitionByAction(findings)

                // Batch trash via NSWorkspace. On macOS 26, `recycle` no longer
                // auto-plays the "move to trash" sound from a regular app
                // context — play it ourselves from the bundled system sound
                // so users still get the familiar audio cue.
                if !trashables.isEmpty {
                    await MainActor.run { Self.playTrashSound() }
                    let result = await Self.recycleBatch(trashables)
                    for finding in trashables {
                        // NSWorkspace returns a mapping keyed by the URL we
                        // passed in — but the URL's Hashable equality is
                        // picky about trailing slashes and standardization.
                        // Match by path string to be safe.
                        let stdPath = (finding.presentationPath as NSString).standardizingPath
                        let trashedTo = result.pathMap[finding.presentationPath]
                            ?? result.pathMap[stdPath]
                        // If there was no error, treat every item in the batch
                        // as successful even when we can't find its trashedTo
                        // in the mapping (URL key fuzziness).
                        let ok = result.error == nil
                        if ok {
                            reclaimed += finding.size ?? 0
                            entries.append(HistoryEntry(
                                timestamp: Date(),
                                ruleId: finding.ruleId,
                                path: finding.presentationPath,
                                trashedTo: trashedTo,
                                sizeBytes: finding.size ?? 0,
                                method: .trash
                            ))
                            continuation.yield(.finishedItem(finding: finding, success: true, error: nil))
                        } else {
                            continuation.yield(.finishedItem(finding: finding, success: false,
                                error: result.error ?? "System denied the Trash operation."))
                        }
                    }
                }

                // Run clean commands sequentially.
                for finding in cleanables {
                    let (success, error, _) = await Self.execute(finding: finding)
                    if success {
                        reclaimed += finding.size ?? 0
                        entries.append(HistoryEntry(
                            timestamp: Date(),
                            ruleId: finding.ruleId,
                            path: finding.presentationPath,
                            trashedTo: nil,
                            sizeBytes: finding.size ?? 0,
                            method: .cleanCommand
                        ))
                    }
                    continuation.yield(.finishedItem(finding: finding, success: success, error: error))
                }

                // Lane 3 — batch all sudo commands into a single osascript
                // invocation so the user gets ONE password prompt, not N.
                if !sudoables.isEmpty {
                    let (ok, err) = await Self.runSudoBatch(sudoables)
                    for finding in sudoables {
                        if ok {
                            reclaimed += finding.size ?? 0
                            entries.append(HistoryEntry(
                                timestamp: Date(),
                                ruleId: finding.ruleId,
                                path: finding.presentationPath,
                                trashedTo: nil,
                                sizeBytes: finding.size ?? 0,
                                method: .cleanCommand
                            ))
                        }
                        continuation.yield(.finishedItem(finding: finding, success: ok, error: err))
                    }
                }

                await history.append(entries)
                continuation.yield(.finishedAll(reclaimed: reclaimed, entries: entries))
                continuation.finish()
            }
        }
    }

    private static func partitionByAction(_ findings: [Finding]) -> (trashables: [Finding], cleanables: [Finding], sudoables: [Finding]) {
        var trashables: [Finding] = []
        var cleanables: [Finding] = []
        var sudoables: [Finding] = []
        for f in findings {
            guard DenyList.isAllowed(f.presentationPath) else { continue }
            switch f.action {
            case .trash: trashables.append(f)
            case .cleanCommand: cleanables.append(f)
            case .shellSudo: sudoables.append(f)
            }
        }
        return (trashables, cleanables, sudoables)
    }

    struct RecycleResult {
        let pathMap: [String: String]   // originalPath → trashedPath
        let error: String?
    }

    /// macOS 26 ships two trash cues:
    ///   - `finder/move to trash.aif`  — longer crumple-paper sound
    ///   - `dock/drag to trash.aif`    — the short classic whoosh
    /// The Dock one is what most users expect when something gets trashed.
    @MainActor private static var cachedTrashSound: NSSound? = {
        let path = "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/dock/drag to trash.aif"
        return NSSound(contentsOfFile: path, byReference: true)
    }()

    @MainActor
    static func playTrashSound() {
        guard let sound = cachedTrashSound else { return }
        // `stop()` then `play()` so rapid successive deletions restart the
        // cue cleanly instead of being ignored because it's already playing.
        sound.stop()
        sound.play()
    }

    /// Call NSWorkspace.recycle once with all URLs — plays the system trash
    /// sound and the Finder animation.
    private static func recycleBatch(_ findings: [Finding]) async -> RecycleResult {
        let urls = findings.map { URL(fileURLWithPath: $0.presentationPath) }
        return await withCheckedContinuation { (continuation: CheckedContinuation<RecycleResult, Never>) in
            NSWorkspace.shared.recycle(urls) { mapping, error in
                var pathMap: [String: String] = [:]
                for (orig, trashed) in mapping {
                    pathMap[orig.path] = trashed.path
                }
                continuation.resume(returning: RecycleResult(
                    pathMap: pathMap,
                    error: error?.localizedDescription
                ))
            }
        }
    }

    private static func execute(finding: Finding) async -> (Bool, String?, String?) {
        // Final-chance safety net — redundant with DiscoveryCoordinator's filter,
        // cheap, prevents deletion if something terrible changed between scan
        // and click.
        guard DenyList.isAllowed(finding.presentationPath) else {
            return (false, "Refused: deny-listed path.", nil)
        }

        switch finding.action {
        case .trash:
            return await trash(finding)
        case .cleanCommand(let kind):
            return await runClean(kind: kind, finding: finding)
        case .shellSudo:
            // Sudo findings are handled in a batched osascript call; this
            // per-item path is never reached for them.
            return (false, "Sudo findings must go through runSudoBatch.", nil)
        }
    }

    private static func trash(_ finding: Finding) async -> (Bool, String?, String?) {
        let url = URL(fileURLWithPath: finding.presentationPath)
        do {
            var resulting: NSURL?
            try FileManager.default.trashItem(at: url, resultingItemURL: &resulting)
            return (true, nil, resulting?.path)
        } catch {
            // If Trash fails with EACCES and this is the Go module cache, fall
            // back to `go clean -modcache` which handles read-only files.
            if finding.ruleId == "go.mod-cache" {
                let (ok, err, _) = await runClean(kind: .goModCacheClean, finding: finding)
                return (ok, err, nil)
            }
            return (false, error.localizedDescription, nil)
        }
    }

    private static func runClean(kind: CleanAction.CleanCommandKind, finding: Finding) async -> (Bool, String?, String?) {
        let (executable, args, cwd) = resolveCommand(kind: kind, finding: finding)
        guard let executable else {
            return (false, "Tool not found on PATH for \(kind.rawValue).", nil)
        }

        let p = Process()
        p.executableURL = executable
        p.arguments = args
        if let cwd { p.currentDirectoryURL = cwd }
        let out = Pipe(); let err = Pipe()
        p.standardOutput = out
        p.standardError = err

        return await withCheckedContinuation { (c: CheckedContinuation<(Bool, String?, String?), Never>) in
            p.terminationHandler = { proc in
                let data = err.fileHandleForReading.availableData
                let msg = String(data: data, encoding: .utf8).flatMap { $0.isEmpty ? nil : $0 }
                c.resume(returning: (proc.terminationStatus == 0, msg, nil))
            }
            do {
                try p.run()
            } catch {
                c.resume(returning: (false, error.localizedDescription, nil))
            }
        }
    }

    /// Find the binary for the given clean command via a minimal PATH search.
    /// Falls back to common Homebrew and XDG locations that dev tools live in.
    private static func resolveCommand(
        kind: CleanAction.CleanCommandKind, finding: Finding
    ) -> (URL?, [String], URL?) {
        let cwd = finding.projectPath.map { URL(fileURLWithPath: $0) }
        switch kind {
        case .pnpmStorePrune:
            return (which("pnpm"), ["store", "prune"], nil)
        case .goModCacheClean:
            return (which("go"), ["clean", "-modcache"], nil)
        case .bazelExpunge:
            return (which("bazel"), ["clean", "--expunge"], cwd)
        case .simctlDeleteUnavailable:
            return (URL(fileURLWithPath: "/usr/bin/xcrun"),
                    ["simctl", "delete", "unavailable"], nil)
        case .ollamaRm:
            let comps = URL(fileURLWithPath: finding.presentationPath).pathComponents
            guard let tag = comps.last,
                  comps.count >= 2 else { return (nil, [], nil) }
            let model = comps[comps.count - 2]
            return (which("ollama"), ["rm", "\(model):\(tag)"], nil)
        case .brewCleanup:
            return (which("brew"), ["cleanup", "--prune=all"], nil)
        case .simctlRuntimeDeleteUnavailable:
            return (URL(fileURLWithPath: "/usr/bin/xcrun"),
                    ["simctl", "runtime", "delete", "unavailable"], nil)
        }
    }

    /// Human-readable rendering of the command we'd run. Lane-2 and lane-3
    /// findings both surface a preview in the confirmation sheet.
    static func previewCommand(for finding: Finding) -> String? {
        switch finding.action {
        case .cleanCommand(let kind):
            let (exec, args, _) = resolveCommand(kind: kind, finding: finding)
            let name = exec?.lastPathComponent ?? kind.rawValue
            return ([name] + args).joined(separator: " ")
        case .shellSudo(let kind):
            return "sudo " + sudoShellCommand(kind: kind, finding: finding)
        case .trash:
            return nil
        }
    }

    // MARK: - Lane 3 (sudo via osascript)

    /// Raw shell command for a sudo kind. No `sudo` prefix — osascript's
    /// `with administrator privileges` gives us root for the whole script.
    private static func sudoShellCommand(kind: CleanAction.SudoCommandKind, finding: Finding) -> String {
        switch kind {
        case .nixCollectGarbage:   return "/nix/var/nix/profiles/default/bin/nix-collect-garbage -d"
        case .nixLogsRm:           return "/bin/rm -rf /nix/var/log/nix"
        case .macPortsCleanAll:    return "/opt/local/bin/port clean --all installed"
        case .kdkRm:
            // Per-item: shell-escape the finding's path
            let escaped = finding.presentationPath
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "/bin/rm -rf \"\(escaped)\""
        }
    }

    /// Batch all selected sudo commands into one `do shell script …
    /// with administrator privileges` invocation — one password prompt for
    /// the whole lot. Deduplicates identical commands so selecting all three
    /// MacPorts paths doesn't run `port clean` three times.
    private static func runSudoBatch(_ findings: [Finding]) async -> (success: Bool, error: String?) {
        // Unique shell commands, preserving order
        var seen: Set<String> = []
        var commands: [String] = []
        for f in findings {
            guard case let .shellSudo(kind) = f.action else { continue }
            let cmd = sudoShellCommand(kind: kind, finding: f)
            if seen.insert(cmd).inserted {
                commands.append(cmd + " 2>&1")
            }
        }
        guard !commands.isEmpty else { return (true, nil) }

        let shell = commands.joined(separator: "; ")
        let escaped = shell
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"

        return await withCheckedContinuation { (c: CheckedContinuation<(Bool, String?), Never>) in
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            p.arguments = ["-e", script]
            let stderr = Pipe()
            p.standardError = stderr
            let stdout = Pipe()
            p.standardOutput = stdout
            p.terminationHandler = { proc in
                let errData = stderr.fileHandleForReading.availableData
                let errMsg = String(data: errData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if proc.terminationStatus == 0 {
                    c.resume(returning: (true, nil))
                } else if errMsg?.contains("(-128)") == true {
                    // User cancelled the authentication dialog.
                    c.resume(returning: (false, "Authentication cancelled."))
                } else {
                    c.resume(returning: (false, errMsg.flatMap { $0.isEmpty ? nil : $0 }
                                         ?? "osascript exit \(proc.terminationStatus)"))
                }
            }
            do {
                try p.run()
            } catch {
                c.resume(returning: (false, error.localizedDescription))
            }
        }
    }

    /// Minimal PATH search — standard system locations plus Homebrew.
    private static func which(_ tool: String) -> URL? {
        let dirs = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            "/bin",
            NSHomeDirectory() + "/.cargo/bin",
            NSHomeDirectory() + "/.bun/bin",
            NSHomeDirectory() + "/.local/bin",
            NSHomeDirectory() + "/go/bin",
        ]
        for d in dirs {
            let p = "\(d)/\(tool)"
            if FileManager.default.isExecutableFile(atPath: p) {
                return URL(fileURLWithPath: p)
            }
        }
        return nil
    }
}
