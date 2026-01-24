import SwiftUI

struct AdaptiveCountdownSchedule: TimelineSchedule {
    let eventDate: Date
    let secondsThreshold: TimeInterval

    init(eventDate: Date, secondsThreshold: TimeInterval = 300) {
        self.eventDate = eventDate
        self.secondsThreshold = secondsThreshold
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries {
        Entries(eventDate: eventDate, secondsThreshold: secondsThreshold, startDate: startDate)
    }

    struct Entries: Sequence, IteratorProtocol {
        let eventDate: Date
        let secondsThreshold: TimeInterval
        var current: Date

        init(eventDate: Date, secondsThreshold: TimeInterval, startDate: Date) {
            self.eventDate = eventDate
            self.secondsThreshold = secondsThreshold
            self.current = startDate
        }

        mutating func next() -> Date? {
            guard current < eventDate.addingTimeInterval(60) else { return nil }

            let distance = eventDate.timeIntervalSince(current)
            let interval: TimeInterval = distance <= secondsThreshold ? 1 : 60

            let entry = current
            current = current.addingTimeInterval(interval)
            return entry
        }
    }
}
