import Foundation

/// Parses a `.cruftignore` file (falling back to legacy `.regenignore` /
/// `.devcleanupignore` names). Strict subtract-only semantics: a file in
/// a project can only *narrow* what Cruft deletes inside its own subtree.
/// It cannot add new paths.
///
/// Syntax (gitignore-subset):
/// ```
/// # a comment
/// vendor/third-party/     // exclude this path from all rules
/// **/do-not-touch/**
///
/// [node.modules] packages/legacy/   // scoped: only this rule ignores this path
/// ```
struct IgnoreRules: Sendable, Hashable {
    let unscoped: [String]              // glob patterns
    let scoped: [String: [String]]      // rule-id → glob patterns

    static let empty = IgnoreRules(unscoped: [], scoped: [:])

    func matches(path: String, ruleId: String, relativeTo base: String) -> Bool {
        let rel = path.hasPrefix(base + "/") ? String(path.dropFirst(base.count + 1)) : path
        if unscoped.contains(where: { matchGlob($0, rel) }) { return true }
        if let scoped = scoped[ruleId], scoped.contains(where: { matchGlob($0, rel) }) { return true }
        return false
    }
}

enum IgnoreParser {
    /// Load an ignore file from the given project root, if present.
    /// Looks for `.cruftignore`, then legacy `.regenignore` / `.devcleanupignore`.
    static func loadIfPresent(in projectRoot: URL) -> IgnoreRules {
        for name in [".cruftignore", ".regenignore", ".devcleanupignore"] {
            let url = projectRoot.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path),
               let raw = try? String(contentsOf: url, encoding: .utf8) {
                return parse(raw)
            }
        }
        return .empty
    }

    static func parse(_ text: String) -> IgnoreRules {
        var unscoped: [String] = []
        var scoped: [String: [String]] = [:]

        for rawLine in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            if line.hasPrefix("["), let closeIdx = line.firstIndex(of: "]") {
                let ruleId = String(line[line.index(after: line.startIndex)..<closeIdx])
                let rest = line[line.index(after: closeIdx)...].trimmingCharacters(in: .whitespaces)
                if !rest.isEmpty, isSafePattern(rest) {
                    scoped[ruleId, default: []].append(rest)
                }
            } else if isSafePattern(line) {
                unscoped.append(line)
            }
        }

        return IgnoreRules(unscoped: unscoped, scoped: scoped)
    }

    /// Subtract-only: no absolute paths, no parent-dir escapes, no tildes.
    private static func isSafePattern(_ p: String) -> Bool {
        !p.hasPrefix("/") && !p.contains("..") && !p.hasPrefix("~")
    }
}

/// Minimal gitignore-style glob matcher. Supports `*` (no slash), `**` (any
/// depth), and trailing `/` for directory-only matches.
func matchGlob(_ pattern: String, _ path: String) -> Bool {
    // Compile the pattern into a regex on demand. For a tool matching ≤ a few
    // dozen rules against a few thousand paths this is plenty fast; if it ever
    // becomes hot we can memoize.
    let p = pattern.hasSuffix("/") ? String(pattern.dropLast()) : pattern
    var regex = "^"
    var i = p.startIndex
    while i < p.endIndex {
        let c = p[i]
        switch c {
        case "*":
            let next = p.index(after: i)
            if next < p.endIndex, p[next] == "*" {
                regex += ".*"
                i = p.index(after: next)
                if i < p.endIndex, p[i] == "/" { i = p.index(after: i) }
                continue
            } else {
                regex += "[^/]*"
            }
        case "?": regex += "[^/]"
        case ".", "(", ")", "+", "|", "^", "$", "@", "%", "\\", "{", "}", "[", "]":
            regex += "\\\(c)"
        default:
            regex += String(c)
        }
        i = p.index(after: i)
    }
    regex += "(/.*)?$"
    return path.range(of: regex, options: .regularExpression) != nil
}
