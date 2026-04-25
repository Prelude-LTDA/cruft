import Foundation

/// Runs a vendor-specific dry-run command to get the actual predicted
/// reclaim for rules where disk-size ≠ reclaimable-size (e.g. `brew cleanup`).
enum CustomSizerRunner {

    /// Entry point. Returns bytes (or 0 on any failure — the UI still renders,
    /// just with "0 B" until the user runs it for real).
    static func run(_ kind: CustomSizerKind) async -> Int64 {
        switch kind {
        case .brewCleanupDryRun:
            return await brewCleanupDryRun()
        case .simctlDeleteUnavailable:
            return await simctlDeleteUnavailableDryRun()
        case .simctlRuntimeDeleteUnavailable:
            return await simctlRuntimeDeleteUnavailableDryRun()
        }
    }

    // MARK: - Simulator dry-runs

    /// Sum of the on-disk size of every simulator device that
    /// `xcrun simctl delete unavailable` would remove — devices whose
    /// `isAvailable` is false, or whose `availabilityError` is non-empty.
    /// `dataPath` in the JSON points at the device's `data/` subfolder;
    /// the full device directory is one level up and is what actually
    /// gets removed.
    private static func simctlDeleteUnavailableDryRun() async -> Int64 {
        let output = await runProcess(
            executable: URL(fileURLWithPath: "/usr/bin/xcrun"),
            args: ["simctl", "list", "--json", "devices"]
        )
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]]
        else {
            return 0
        }

        var total: Int64 = 0
        var seen: Set<String> = []   // defensive dedup on the device root path
        for (_, group) in devices {
            for device in group {
                if !isDeviceUnavailable(device) { continue }
                guard let dataPath = device["dataPath"] as? String else { continue }
                let root = (dataPath as NSString).deletingLastPathComponent
                if !seen.insert(root).inserted { continue }
                total += directorySize(atPath: root)
            }
        }
        return total
    }

    /// Sum of the on-disk size of every simulator runtime that
    /// `xcrun simctl runtime delete unavailable` would remove. A runtime
    /// qualifies when its `state` is anything other than "Ready" /
    /// "Usable" and it's marked `deletable: true` (Apple tracks both
    /// disk-image-backed and bundled-with-Xcode runtimes here).
    private static func simctlRuntimeDeleteUnavailableDryRun() async -> Int64 {
        let output = await runProcess(
            executable: URL(fileURLWithPath: "/usr/bin/xcrun"),
            args: ["simctl", "runtime", "list", "--json"]
        )
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return 0
        }

        var total: Int64 = 0
        var seen: Set<String> = []
        for (_, value) in json {
            guard let runtime = value as? [String: Any] else { continue }
            if !isRuntimeUnavailable(runtime) { continue }
            guard let path = runtime["path"] as? String else { continue }
            if !seen.insert(path).inserted { continue }
            total += directorySize(atPath: path)
        }
        return total
    }

    private static func isDeviceUnavailable(_ device: [String: Any]) -> Bool {
        if let available = device["isAvailable"] as? Bool, available == false {
            return true
        }
        if let err = device["availabilityError"] as? String, !err.isEmpty {
            return true
        }
        return false
    }

    private static func isRuntimeUnavailable(_ runtime: [String: Any]) -> Bool {
        // The safest signal across macOS versions: any non-ready state
        // paired with `deletable: true`. `simctl runtime delete unavailable`
        // uses the same heuristic under the hood.
        let state = (runtime["state"] as? String ?? "").lowercased()
        let deletable = runtime["deletable"] as? Bool ?? false
        guard deletable else { return false }
        let unavailableStates: Set<String> = [
            "unusable", "unavailable", "unsupported",
            "disabled", "corrupted", "non-ready"
        ]
        if unavailableStates.contains(state) { return true }
        // Some runtimes report `state: "Ready"` but `isAvailable: false`;
        // simctl still includes those in `delete unavailable`.
        if let available = runtime["isAvailable"] as? Bool, available == false {
            return true
        }
        return false
    }

    /// Walks `path` and sums allocated-file sizes. Used for the two
    /// simctl sizers — handles sparse / clone-backed files correctly via
    /// `.totalFileAllocatedSizeKey` (matches what Finder's "On Disk" shows
    /// rather than logical sum of blocks).
    private static func directorySize(atPath path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        let keys: [URLResourceKey] = [.totalFileAllocatedSizeKey, .isRegularFileKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true,
                  let size = values.totalFileAllocatedSize
            else { continue }
            total += Int64(size)
        }
        return total
    }

    private static func brewCleanupDryRun() async -> Int64 {
        guard let brew = which("brew") else { return 0 }
        let output = await runProcess(executable: brew, args: ["cleanup", "--dry-run", "--prune=all"])
        return parseBrewReclaim(output)
    }

    /// Parses the `==> This operation would free approximately X of disk space.`
    /// summary line. Falls back to 0 if absent (brew emits nothing when there's
    /// nothing to clean — the right answer is zero).
    static func parseBrewReclaim(_ output: String) -> Int64 {
        // Match "N[.d] [KMGT]B" after "approximately"
        let pattern = #"approximately\s+([\d.]+)\s*([KMGT]?)B"#
        guard let range = output.range(of: pattern, options: .regularExpression) else {
            return 0
        }
        let match = String(output[range])
        // Pull the number
        let numPattern = #"[\d.]+"#
        guard let numRange = match.range(of: numPattern, options: .regularExpression),
              let value = Double(match[numRange]) else {
            return 0
        }
        // Pull the unit prefix (one of K / M / G / T, or empty)
        let unitChar: String
        if let uRange = match.range(of: #"[KMGT](?=B)"#, options: .regularExpression) {
            unitChar = String(match[uRange])
        } else {
            unitChar = ""
        }
        let multiplier: Double
        switch unitChar {
        case "K": multiplier = 1_000
        case "M": multiplier = 1_000_000
        case "G": multiplier = 1_000_000_000
        case "T": multiplier = 1_000_000_000_000
        default:  multiplier = 1
        }
        return Int64(value * multiplier)
    }

    // MARK: - Helpers

    private static func which(_ tool: String) -> URL? {
        let dirs = ["/opt/homebrew/bin", "/usr/local/bin", "/usr/bin", "/bin"]
        for d in dirs {
            let p = "\(d)/\(tool)"
            if FileManager.default.isExecutableFile(atPath: p) {
                return URL(fileURLWithPath: p)
            }
        }
        return nil
    }

    private static func runProcess(executable: URL, args: [String]) async -> String {
        await withCheckedContinuation { (c: CheckedContinuation<String, Never>) in
            let p = Process()
            p.executableURL = executable
            p.arguments = args
            let out = Pipe()
            p.standardOutput = out
            p.standardError = out
            p.terminationHandler = { _ in
                let data = out.fileHandleForReading.readDataToEndOfFile()
                c.resume(returning: String(data: data, encoding: .utf8) ?? "")
            }
            do {
                try p.run()
            } catch {
                c.resume(returning: "")
            }
        }
    }
}
