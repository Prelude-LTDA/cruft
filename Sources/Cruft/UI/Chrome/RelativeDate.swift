import Foundation

/// Shared formatters for the "modified" column. Relative for display, absolute
/// for tooltip.
enum DateDisplay {
    nonisolated(unsafe) private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        f.dateTimeStyle = .numeric
        return f
    }()

    private static let absolute: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    static func relativeText(_ date: Date?) -> String {
        guard let date else { return "—" }
        // RelativeDateTimeFormatter rounds to "in 0 sec" for moments inside
        // the current second instead of saying "Just now". Special-case the last
        // few seconds so freshly-written rows read naturally.
        let delta = abs(date.timeIntervalSinceNow)
        if delta < 5 { return "Just now" }
        return relative.localizedString(for: date, relativeTo: Date())
    }

    static func absoluteText(_ date: Date?) -> String {
        guard let date else { return "" }
        return absolute.string(from: date)
    }
}
