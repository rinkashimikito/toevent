import AppKit
import EventKit

final class LocalCalendarProvider: CalendarProvider {
    var providerType: CalendarProviderType { .local }
    var account: CalendarAccount { .local }

    var isAuthenticated: Bool {
        let status = CalendarService.shared.authorizationStatus()
        if #available(macOS 14.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }

    func authenticate(presentingWindow: NSWindow?) async throws {
        _ = await CalendarService.shared.requestAccess()
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarIDs: [String]?) async throws -> [Event] {
        let lookahead = endDate.timeIntervalSince(startDate)
        return CalendarService.shared.fetchUpcomingEvents(
            from: calendarIDs,
            lookahead: lookahead,
            priority: []
        )
    }

    func fetchCalendars() async throws -> [CalendarInfo] {
        CalendarService.shared.getCalendars()
    }

    func signOut() async {
        // No-op for local provider
    }
}
