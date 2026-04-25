import Foundation

/// The one piece of safety we actually keep: a hard deny-list of paths we will
/// never trash even if a rule matches one, plus a volume-boundary check so a
/// symlinked `node_modules` pointing to a shared drive can't take the shared
/// drive with it.
///
/// Deliberately tiny and readable — this file is auditable at a glance.
enum DenyList {
    /// Absolute prefixes we refuse to delete under. Expanded lazily.
    static let prefixes: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "\(home)/.ssh",
            "\(home)/.aws",
            "\(home)/.gnupg",
            "\(home)/.config",
            "\(home)/Library/Keychains",
            "\(home)/Library/Mail",
            "\(home)/Library/Messages",
            "/System",
            "/private/var/db",
        ]
    }()

    /// True if this path is safe to trash.
    static func isAllowed(_ path: String) -> Bool {
        let std = (path as NSString).standardizingPath
        for bad in prefixes where std == bad || std.hasPrefix(bad + "/") {
            return false
        }
        return true
    }

    /// Refuse anything whose resolved target is on a different volume than the
    /// declared project root.
    static func crossesVolumeBoundary(_ url: URL, projectRoot: URL?) -> Bool {
        let resolved = url.resolvingSymlinksInPath()
        let deviceA = (try? resolved.resourceValues(forKeys: [.volumeIdentifierKey])
            .volumeIdentifier) as? NSObject

        if let root = projectRoot {
            let deviceB = (try? root.resolvingSymlinksInPath()
                .resourceValues(forKeys: [.volumeIdentifierKey])
                .volumeIdentifier) as? NSObject
            guard let a = deviceA, let b = deviceB else { return false }
            return !a.isEqual(b)
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return !(resolved.path.hasPrefix(home) || resolved.path.hasPrefix("/Library"))
    }
}
