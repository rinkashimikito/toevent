import SwiftUI

struct EventListView: View {
    @EnvironmentObject private var appState: AppState
    var onEventTap: (Event) -> Void = { _ in }

    var body: some View {
        if displayEvents.isEmpty {
            emptyState
        } else {
            eventsList
        }
    }

    private var emptyState: some View {
        Text("All clear")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }

    private var eventsList: some View {
        VStack(spacing: 0) {
            ForEach(groupedEvents, id: \.date) { group in
                if !group.events.isEmpty {
                    daySection(for: group)
                }
            }
        }
    }

    @ViewBuilder
    private func daySection(for group: EventGroup) -> some View {
        // Show date header for non-today events
        if !Calendar.current.isDateInToday(group.date) {
            Text(formatDateHeader(group.date))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .padding(.top, 8)
        }

        let allDay = group.events.filter { $0.isAllDay }
        let timed = group.events.filter { !$0.isAllDay }

        ForEach(appState.hideAllDayEvents ? [] : allDay) { event in
            EventRowView(event: event, onTap: { onEventTap(event) })
        }

        if !allDay.isEmpty && !timed.isEmpty && !appState.hideAllDayEvents {
            Divider()
                .padding(.horizontal, 12)
        }

        ForEach(timed) { event in
            EventRowView(event: event, onTap: { onEventTap(event) })
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    // MARK: - Data

    private var displayEvents: [Event] {
        let events = Array(appState.events.prefix(appState.maxEventsToShow))
        if appState.hideAllDayEvents {
            return events.filter { !$0.isAllDay }
        }
        return events
    }

    private var groupedEvents: [EventGroup] {
        let calendar = Calendar.current
        var groups: [Date: [Event]] = [:]

        for event in displayEvents {
            let dayStart = calendar.startOfDay(for: event.startDate)
            groups[dayStart, default: []].append(event)
        }

        return groups.keys.sorted().map { date in
            EventGroup(date: date, events: groups[date] ?? [])
        }
    }
}

private struct EventGroup {
    let date: Date
    let events: [Event]
}
