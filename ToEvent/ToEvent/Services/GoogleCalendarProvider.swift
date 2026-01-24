import AppKit
import Foundation

enum GoogleCalendarError: Error, LocalizedError {
    case noWindow
    case notAuthenticated
    case authExpired
    case rateLimited
    case networkError(Error)
    case invalidResponse
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .noWindow:
            return "No window available for authentication"
        case .notAuthenticated:
            return "Not authenticated with Google"
        case .authExpired:
            return "Google authentication has expired"
        case .rateLimited:
            return "Rate limited by Google Calendar API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Google Calendar API"
        case .invalidURL:
            return "Invalid URL for API request"
        }
    }
}

final class GoogleCalendarProvider: CalendarProvider {
    let providerType: CalendarProviderType = .google
    let account: CalendarAccount

    private var credentials: OAuthCredentials?
    private let baseURL = "https://www.googleapis.com/calendar/v3"

    init(account: CalendarAccount) {
        self.account = account
        self.credentials = AuthService.shared.getCredentials(for: account.id)
    }

    var isAuthenticated: Bool {
        guard let credentials = credentials else { return false }
        return !credentials.isExpired
    }

    func authenticate(presentingWindow: NSWindow?) async throws {
        guard let window = presentingWindow else {
            throw GoogleCalendarError.noWindow
        }
        credentials = try await AuthService.shared.startOAuthFlow(
            for: .google,
            presentingWindow: window
        )
    }

    func fetchCalendars() async throws -> [CalendarInfo] {
        let data = try await request(path: "/users/me/calendarList")
        let response = try JSONDecoder().decode(GoogleCalendarsResponse.self, from: data)
        return response.items.map { $0.toCalendarInfo(accountId: account.id) }
    }

    func fetchEvents(from startDate: Date, to endDate: Date, calendarIDs: [String]?) async throws -> [Event] {
        let calendars = try await fetchCalendars()
        let targetCalendars: [CalendarInfo]
        if let ids = calendarIDs {
            targetCalendars = calendars.filter { ids.contains($0.id) }
        } else {
            targetCalendars = calendars
        }

        var allEvents: [Event] = []
        for calendar in targetCalendars {
            do {
                let events = try await fetchEventsForCalendar(
                    calendar,
                    from: startDate,
                    to: endDate
                )
                allEvents.append(contentsOf: events)
            } catch {
                // Skip calendar on error, continue with others
                print("Failed to fetch events for calendar \(calendar.title): \(error)")
            }
        }

        return allEvents.sorted { $0.startDate < $1.startDate }
    }

    func signOut() async {
        try? AuthService.shared.deleteAccount(account.id)
        credentials = nil
    }

    // MARK: - Private

    private func fetchEventsForCalendar(
        _ calendar: CalendarInfo,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [Event] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let queryItems = [
            URLQueryItem(name: "timeMin", value: formatter.string(from: startDate)),
            URLQueryItem(name: "timeMax", value: formatter.string(from: endDate)),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime"),
            URLQueryItem(name: "maxResults", value: "250")
        ]

        let encodedCalendarId = calendar.id.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) ?? calendar.id

        let data = try await request(
            path: "/calendars/\(encodedCalendarId)/events",
            queryItems: queryItems
        )

        let response = try JSONDecoder().decode(GoogleEventsResponse.self, from: data)
        return (response.items ?? []).compactMap { googleEvent in
            googleEvent.toEvent(
                calendarId: calendar.id,
                calendarTitle: calendar.title,
                calendarColor: calendar.color,
                accountId: account.id
            )
        }
    }

    private func request(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Data {
        guard let credentials = credentials else {
            throw GoogleCalendarError.notAuthenticated
        }

        if credentials.isExpired {
            throw GoogleCalendarError.authExpired
        }

        guard var components = URLComponents(string: baseURL + path) else {
            throw GoogleCalendarError.invalidURL
        }

        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw GoogleCalendarError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw GoogleCalendarError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleCalendarError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            throw GoogleCalendarError.authExpired
        case 403, 429:
            throw GoogleCalendarError.rateLimited
        default:
            throw GoogleCalendarError.invalidResponse
        }
    }
}
