import Foundation

struct OAuthCredentials: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let accountId: String
    let providerType: CalendarProviderType

    var isExpired: Bool {
        expiresAt <= Date()
    }

    var needsRefresh: Bool {
        expiresAt <= Date().addingTimeInterval(5 * 60)
    }
}
