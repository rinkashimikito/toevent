import AppKit

protocol CalendarProvider {
    var providerType: CalendarProviderType { get }
    var account: CalendarAccount { get }
    var isAuthenticated: Bool { get }

    func authenticate(presentingWindow: NSWindow?) async throws
    func fetchEvents(from: Date, to: Date, calendarIDs: [String]?) async throws -> [Event]
    func fetchCalendars() async throws -> [CalendarInfo]
    func signOut() async
}
