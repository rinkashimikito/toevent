import Foundation

enum DateFormatters {
    private static let relativeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        formatter.maximumUnitCount = 1
        return formatter
    }()

    static func formatRelativeTime(until date: Date, from now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            return "now"
        }

        if interval < 60 {
            return "in 1m"
        }

        guard let formatted = relativeFormatter.string(from: interval) else {
            return "now"
        }

        return "in \(formatted)"
    }

    static func formatHybridCountdown(until date: Date, from now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            return "Now"
        }

        if interval < 60 {
            return String(format: "%ds", Int(interval))
        }

        if interval < 300 {
            let minutes = Int(interval) / 60
            let seconds = Int(interval) % 60
            return String(format: "%dm %02ds", minutes, seconds)
        }

        if interval < 3600 {
            let minutes = Int(interval) / 60
            return "\(minutes)m"
        }

        if interval < 86400 {
            let hours = Int(interval) / 3600
            let minutes = (Int(interval) % 3600) / 60
            if minutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(minutes)m"
        }

        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours == 0 && minutes == 0 {
            return "\(days)d"
        }
        if hours == 0 {
            return "\(days)d \(minutes)m"
        }
        if minutes == 0 {
            return "\(days)d \(hours)h"
        }
        return "\(days)d \(hours)h \(minutes)m"
    }

    static func shouldShowSeconds(until date: Date, from now: Date = Date()) -> Bool {
        let interval = date.timeIntervalSince(now)
        return interval > 0 && interval < 300
    }

    private static let absoluteTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    static func formatAbsoluteTime(_ date: Date) -> String {
        return absoluteTimeFormatter.string(from: date)
    }

    static func formatNaturalLanguage(until date: Date, from now: Date = Date()) -> String {
        let interval = date.timeIntervalSince(now)

        if interval <= 0 {
            return "now"
        }

        if interval < 60 {
            return "now"
        }

        if interval < 300 {
            return "very soon"
        }

        if interval < 900 {
            return "soon"
        }

        if interval < 1800 {
            return "shortly"
        }

        if interval < 3600 {
            return "in under an hour"
        }

        if interval < 7200 {
            return "in about an hour"
        }

        let hours = Int(interval / 3600)
        return "in \(hours) hours"
    }
}
