import Foundation

/// Directly probes the ~30 global cache paths in the rule catalog. These are
/// invisible to Spotlight (they live under `~/Library`, which is excluded) and
/// their existence is deterministic — just stat them.
struct FixedPathProbe: Sendable {
    let rules: [Rule]

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

            default:
                continue
            }
        }
        return out
    }
}
