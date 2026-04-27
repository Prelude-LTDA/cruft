import Foundation
import Darwin

/// Directly probes the ~30 global cache paths in the rule catalog. These are
/// invisible to Spotlight (they live under `~/Library`, which is excluded) and
/// their existence is deterministic — just stat them.
struct FixedPathProbe: Sendable {
    let rules: [Rule]

    /// `$DARWIN_USER_CACHE_DIR` — the per-user-session cache root at
    /// `/private/var/folders/<X>/<Y>/C/`. Resolved once via libc's
    /// `confstr(_CS_DARWIN_USER_CACHE_DIR)`. Always ends with a trailing `/`.
    private static let darwinUserCacheDir: String? = {
        let key = Int32(_CS_DARWIN_USER_CACHE_DIR)
        let len = confstr(key, nil, 0)
        guard len > 0 else { return nil }
        var buf = [UInt8](repeating: 0, count: len)
        let written = buf.withUnsafeMutableBytes {
            confstr(key, $0.baseAddress?.assumingMemoryBound(to: CChar.self), len)
        }
        guard written > 0 else { return nil }
        // confstr writes a NUL-terminated string; trim it before decoding.
        if let nul = buf.firstIndex(of: 0) {
            return String(decoding: buf[..<nul], as: UTF8.self)
        }
        return String(decoding: buf, as: UTF8.self)
    }()

    func probe() -> [(rule: Rule, url: URL)] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var out: [(Rule, URL)] = []
        for r in rules {
            switch r.matcher {
            case let .fixedPath(rel):
                let full = "\(home)/\(rel)"
                if FileManager.default.fileExists(atPath: full) {
                    out.append((r, URL(fileURLWithPath: full)))
                }

            case let .fixedPathChildren(rel):
                let parent = "\(home)/\(rel)"
                guard let names = try? FileManager.default.contentsOfDirectory(atPath: parent)
                else { continue }
                for name in names where !name.hasPrefix(".") {
                    let childPath = "\(parent)/\(name)"
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: childPath, isDirectory: &isDir),
                       isDir.boolValue {
                        out.append((r, URL(fileURLWithPath: childPath)))
                    }
                }

            case let .fixedPathGrandchildren(rel):
                let root = "\(home)/\(rel)"
                guard let firstLevel = try? FileManager.default.contentsOfDirectory(atPath: root)
                else { continue }
                for first in firstLevel where !first.hasPrefix(".") {
                    let mid = "\(root)/\(first)"
                    var isDir: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: mid, isDirectory: &isDir),
                          isDir.boolValue else { continue }
                    guard let secondLevel = try? FileManager.default.contentsOfDirectory(atPath: mid)
                    else { continue }
                    for second in secondLevel where !second.hasPrefix(".") {
                        let leaf = "\(mid)/\(second)"
                        var leafIsDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: leaf, isDirectory: &leafIsDir),
                           leafIsDir.boolValue {
                            out.append((r, URL(fileURLWithPath: leaf)))
                        }
                    }
                }

            case let .fixedAbsolutePath(absolute):
                if FileManager.default.fileExists(atPath: absolute) {
                    out.append((r, URL(fileURLWithPath: absolute)))
                }

            case let .fixedAbsolutePathChildren(parent):
                guard let names = try? FileManager.default.contentsOfDirectory(atPath: parent)
                else { continue }
                for name in names where !name.hasPrefix(".") {
                    let childPath = "\(parent)/\(name)"
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: childPath, isDirectory: &isDir),
                       isDir.boolValue {
                        out.append((r, URL(fileURLWithPath: childPath)))
                    }
                }

            case let .darwinCachePath(rel):
                guard let base = Self.darwinUserCacheDir else { continue }
                // confstr's value already ends in `/`; strip a leading `/`
                // from `rel` if the rule author included one.
                let trimmed = rel.hasPrefix("/") ? String(rel.dropFirst()) : rel
                let full = "\(base)\(trimmed)"
                if FileManager.default.fileExists(atPath: full) {
                    out.append((r, URL(fileURLWithPath: full)))
                }

            case let .darwinCachePerApp(subdir):
                guard let base = Self.darwinUserCacheDir else { continue }
                // Trim trailing `/` for clean concatenation.
                let baseDir = base.hasSuffix("/") ? String(base.dropLast()) : base
                Self.probePerBundle(rule: r, root: baseDir, subdir: subdir, into: &out)

            case let .libraryCachesPerApp(subdir):
                let root = "\(home)/Library/Caches"
                Self.probePerBundle(rule: r, root: root, subdir: subdir, into: &out)

            case let .libraryAppSupportPerApp(subdir):
                let root = "\(home)/Library/Application Support"
                Self.probePerBundle(rule: r, root: root, subdir: subdir, into: &out)

            default:
                continue
            }
        }
        return out
    }

    /// Walks `root`'s direct children and emits `(rule, child/subdir)` for
    /// every child whose `<child>/<subdir>` exists as a directory. Skips
    /// dotfiles and any child whose name happens to equal the subdir we're
    /// looking for (defends against framework-name top-levels in the
    /// Darwin cache root colliding with a per-bundle rule).
    private static func probePerBundle(
        rule: Rule,
        root: String,
        subdir: String,
        into out: inout [(Rule, URL)]
    ) {
        guard let bundles = try? FileManager.default.contentsOfDirectory(atPath: root)
        else { return }
        for bundle in bundles where !bundle.hasPrefix(".") {
            if bundle == subdir { continue }
            let candidate = "\(root)/\(bundle)/\(subdir)"
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: candidate, isDirectory: &isDir),
               isDir.boolValue {
                out.append((rule, URL(fileURLWithPath: candidate)))
            }
        }
    }
}
