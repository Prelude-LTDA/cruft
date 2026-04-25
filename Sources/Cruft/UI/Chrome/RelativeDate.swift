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
        return relative.localizedString(for: date, relativeTo: Date())
    }

    static func absoluteText(_ date: Date?) -> String {
        guard let date else { return "" }
        return absolute.string(from: date)
    }
}
