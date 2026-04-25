import Foundation

/// Computes directory sizes while skipping hardlink double-counting (pnpm's
/// content-addressed store and Xcode's DerivedData clones are the canonical
/// offenders — without inode-awareness the "reclaimable" number can be wrong
/// by 20–40% on pnpm-heavy machines).
///
/// Implementation: a sharded set of 16 actors keyed by `inode & 0xF` so the
/// inode check isn't a single serial bottleneck.
actor InodeSet {
    private var seen: Set<UInt64> = []
    @discardableResult
    func insert(_ key: UInt64) -> Bool {
        if seen.contains(key) { return false }
        seen.insert(key)
        return true
    }
}

final class InodeRegistry: Sendable {
    private let shards: [InodeSet]
    init() {
        self.shards = (0..<16).map { _ in InodeSet() }
    }
    func insert(devInode: UInt64) async -> Bool {
        // Shard by the low 4 bits of the inode half.
        await shards[Int(devInode & 0xF)].insert(devInode)
    }
}

struct Sizer: Sendable {
    let registry: InodeRegistry

    init(registry: InodeRegistry = InodeRegistry()) {
        self.registry = registry
    }

    /// Compute the size of a directory, deduping by (dev, inode). Honors
    /// cancellation. Returns 0 if we can't enumerate it.
    func size(of url: URL) async -> Int64 {
        let keys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .totalFileAllocatedSizeKey,
            .fileAllocatedSizeKey,
        ]

        // For a plain file, just stat it.
        if let v = try? url.resourceValues(forKeys: keys), v.isRegularFile == true {
            let key = packedDevInode(url: url)
            if key != 0 {
                let fresh = await registry.insert(devInode: key)
                if !fresh { return 0 }
            }
            return Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0)
        }

        guard let en = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: []
        ) else { return 0 }

        var total: Int64 = 0
        var counter = 0
        while let obj = en.nextObject() {
            guard let item = obj as? URL else { continue }
            counter += 1
            if counter & 0x1FF == 0 {
                if Task.isCancelled { return total }
                await Task.yield()
            }
            guard let v = try? item.resourceValues(forKeys: keys) else { continue }
            guard v.isRegularFile == true, v.isSymbolicLink != true else { continue }
            let key = packedDevInode(url: item)
            if key != 0 {
                let fresh = await registry.insert(devInode: key)
                if !fresh { continue }
            }
            total += Int64(v.totalFileAllocatedSize ?? v.fileAllocatedSize ?? 0)
        }
        return total
    }
}
