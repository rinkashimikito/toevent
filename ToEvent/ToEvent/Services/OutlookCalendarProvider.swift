import AppKit
import Foundation

enum OutlookCalendarError: Error, LocalizedError {
    case noWindow
    case notAuthenticated
    case authExpired
    case rateLimited(retryAfter: Int?)
    case networkError(Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noWindow:
            return "No window available for authentication"
        case .notAuthenticated:
            return "Not authenticated with Microsoft"
        case .authExpired:
            return "Microsoft authentication has expired"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Retry after \(seconds) seconds"
            }
            return "Rate limited by Microsoft Graph API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from Microsoft Graph API"
        }
    }
}

final class OutlookCalendarProvider: CalendarProvider {
    let providerType: CalendarProviderType = .outlook
    let account: CalendarAccount

    private var credentials: OAuthCredentials?
    private let baseURL = "https://graph.microsoft.com/v1.0"

    init(account: CalendarAccount) {
        self.account = account
        self.credentials = AuthService.shared.getCredentials(for: account.id)
    }

    var isAuthenticated: Bool {
        credentials != nil && !(credentials?.isExpired ?? true)
    }

    func authenticate(presentingWindow: NSWindow?) async throws {
        guard let window = presentingWindow else {
            throw OutlookCalendarError.noWindow
        }
        credentials = try await AuthService.shared.startOAuthFlow(for: .outlook, presentingWindow: window)
    }

    func fetchCalendars() async throws -> [CalendarInfo] {
        let data = try await request(path: "/me/calendars")
        let response = try JSONDecoder().decode(MicrosoftCalendarsResponse.self, from: data)
        return response.value.map { $0.toCalendarInfo(accountId: account.id) }
    }

    func fetchEvents(from: Date, to: Date, calendarIDs: [String]?) async throws -> [Event] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        let queryItems = [
            URLQueryItem(name: "startDateTime", value: formatter.string(from: from)),
            URLQueryItem(name: "endDateTime", value: formatter.string(from: to))
        ]

        var allEvents: [Event] = []
        let calendars = try await fetchCalendars()
        let targetCalendars = calendarIDs.map { ids in
            calendars.filter { ids.contains($0.id) }
        } ?? calendars

        for calendar in targetCalendars {
            let encodedId = calendar.id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendar.id
            let path = "/me/calendars/\(encodedId)/calendarView"

            do {
                let data = try await request(path: path, queryItems: queryItems)
                let response = try JSONDecoder().decode(MicrosoftEventsResponse.self, from: data)
                let events = (response.value ?? [])
                    .filter { !($0.isCancelled ?? false) }
                    .map { $0.toEvent(
                        calendarId: calendar.id,
                        calendarTitle: calendar.title,
                        calendarColor: calendar.color,
                        accountId: account.id
                    )}
                allEvents.append(contentsOf: events)
            } catch OutlookCalendarError.authExpired {
                throw OutlookCalendarError.authExpired
            } catch {
                continue
            }
        }

        return allEvents.sorted { $0.startDate < $1.startDate }
    }

    func signOut() async {
        try? AuthService.shared.deleteAccount(account.id)
        credentials = nil
    }

    private func request(path: String, queryItems: [URLQueryItem] = []) async throws -> Data {
        guard let creds = credentials, !creds.isExpired else {
            throw OutlookCalendarError.authExpired
        }

        var components = URLComponents(string: baseURL + path)!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw OutlookCalendarError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(creds.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OutlookCalendarError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OutlookCalendarError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            return data
        case 401:
            throw OutlookCalendarError.authExpired
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) }
            throw OutlookCalendarError.rateLimited(retryAfter: retryAfter)
        default:
            throw OutlookCalendarError.invalidResponse
        }
    }
}
