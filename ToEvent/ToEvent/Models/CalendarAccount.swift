import Foundation

struct CalendarAccount: Codable, Identifiable {
    let id: String
    let providerType: CalendarProviderType
    let email: String
    let displayName: String

    static let local = CalendarAccount(
        id: "local",
        providerType: .local,
        email: "System",
        displayName: "Local Calendars"
    )
}
