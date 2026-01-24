import Foundation

extension Array where Element == Event {
    /// Find all pairs of overlapping events
    var conflicts: [(Event, Event)] {
        var result: [(Event, Event)] = []
        let timedEvents = filter { !$0.isAllDay }

        for i in 0..<timedEvents.count {
            for j in (i + 1)..<timedEvents.count {
                let a = timedEvents[i]
                let b = timedEvents[j]

                // Check if intervals overlap
                // a.start < b.end AND b.start < a.end
                if a.startDate < b.endDate && b.startDate < a.endDate {
                    result.append((a, b))
                }
            }
        }

        return result
    }

    /// Get IDs of all events that have conflicts
    var conflictingEventIDs: Set<String> {
        var ids = Set<String>()
        for (a, b) in conflicts {
            ids.insert(a.id)
            ids.insert(b.id)
        }
        return ids
    }

    /// Check if a specific event has conflicts
    func hasConflict(_ event: Event) -> Bool {
        conflictingEventIDs.contains(event.id)
    }
}
