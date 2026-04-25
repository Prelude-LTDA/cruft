import Foundation

/// Given the sibling file list of a `node_modules` directory, pick the
/// runtime that installed it. Presence precedence — NOT mtime — per the
/// critique: bun > pnpm > yarn > npm.
enum RuntimeDetector {
    static func forNodeModules(siblings: Set<String>) -> Runtime {
        if siblings.contains("bun.lockb") || siblings.contains("bun.lock") { return .bun }
        if siblings.contains("pnpm-lock.yaml") { return .pnpm }
        if siblings.contains("yarn.lock") { return .yarn }
        return .npm
    }

    /// Optional runtime overlay for Python projects (venv / .venv).
    /// Looks for a hint of uv / poetry management.
    static func forPythonProject(siblings: Set<String>) -> Runtime? {
        if siblings.contains("uv.lock") { return .uv }
        if siblings.contains("poetry.lock") { return .poetry }
        return nil
    }
}
