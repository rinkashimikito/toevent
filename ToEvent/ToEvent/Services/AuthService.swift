import AuthenticationServices
import AppKit

enum AuthError: Error, LocalizedError {
    case userCancelled
    case invalidResponse
    case tokenExchangeFailed(String)
    case networkError(Error)
    case missingConfiguration

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Authentication was cancelled"
        case .invalidResponse:
            return "Received invalid response from authentication provider"
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .missingConfiguration:
            return "OAuth client ID not configured"
        }
    }
}

private enum GoogleConfig {
    static let clientId = "YOUR_GOOGLE_CLIENT_ID"
    static let redirectUri = "toevent:/oauth/google"
    static let scope = "https://www.googleapis.com/auth/calendar.readonly"
    static let authEndpoint = "https://accounts.google.com/o/oauth2/v2/auth"
    static let tokenEndpoint = "https://oauth2.googleapis.com/token"
}

private enum MicrosoftConfig {
    static let clientId = "YOUR_MICROSOFT_CLIENT_ID"
    static let redirectUri = "toevent://oauth/microsoft"
    static let scope = "Calendars.Read offline_access"
    static let authEndpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
    static let tokenEndpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
}

final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published private(set) var accounts: [CalendarAccount] = []

    private var presentingWindow: NSWindow?
    private let keychainService = KeychainService.shared

    private override init() {
        super.init()
        loadStoredAccounts()
    }

    func startOAuthFlow(
        for provider: CalendarProviderType,
        presentingWindow: NSWindow
    ) async throws -> OAuthCredentials {
        self.presentingWindow = presentingWindow

        guard provider != .local else {
            throw AuthError.invalidResponse
        }

        let (authURL, callbackScheme) = try buildAuthURL(for: provider)
        let callbackURL = try await performWebAuthSession(url: authURL, callbackScheme: callbackScheme)
        let code = try extractAuthorizationCode(from: callbackURL)
        let credentials = try await exchangeCodeForTokens(code: code, provider: provider)

        try keychainService.save(credentials, for: credentials.accountId)

        let account = CalendarAccount(
            id: credentials.accountId,
            providerType: provider,
            email: "Connected Account",
            displayName: provider.displayName
        )
        await MainActor.run {
            if !accounts.contains(where: { $0.id == account.id }) {
                accounts.append(account)
            }
        }

        return credentials
    }

    func loadStoredAccounts() {
        let accountIds = keychainService.listAccountIds()
        accounts = accountIds.compactMap { accountId in
            guard let credentials = keychainService.load(for: accountId) else { return nil }
            return CalendarAccount(
                id: accountId,
                providerType: credentials.providerType,
                email: "Stored Account",
                displayName: credentials.providerType.displayName
            )
        }
    }

    func getCredentials(for accountId: String) -> OAuthCredentials? {
        keychainService.load(for: accountId)
    }

    func deleteAccount(_ accountId: String) throws {
        try keychainService.delete(for: accountId)
        accounts.removeAll { $0.id == accountId }
    }

    private func buildAuthURL(for provider: CalendarProviderType) throws -> (URL, String) {
        let config: (clientId: String, redirectUri: String, scope: String, authEndpoint: String)

        switch provider {
        case .google:
            config = (GoogleConfig.clientId, GoogleConfig.redirectUri, GoogleConfig.scope, GoogleConfig.authEndpoint)
        case .outlook:
            config = (MicrosoftConfig.clientId, MicrosoftConfig.redirectUri, MicrosoftConfig.scope, MicrosoftConfig.authEndpoint)
        case .local:
            throw AuthError.invalidResponse
        }

        guard config.clientId != "YOUR_GOOGLE_CLIENT_ID" && config.clientId != "YOUR_MICROSOFT_CLIENT_ID" else {
            throw AuthError.missingConfiguration
        }

        var components = URLComponents(string: config.authEndpoint)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: config.scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        guard let url = components.url else {
            throw AuthError.invalidResponse
        }

        let scheme = URL(string: config.redirectUri)?.scheme ?? "toevent"
        return (url, scheme)
    }

    private func performWebAuthSession(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error = error as? ASWebAuthenticationSessionError {
                    if error.code == .canceledLogin {
                        continuation.resume(throwing: AuthError.userCancelled)
                    } else {
                        continuation.resume(throwing: AuthError.networkError(error))
                    }
                    return
                }

                if let error = error {
                    continuation.resume(throwing: AuthError.networkError(error))
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.invalidResponse)
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false

            if !session.start() {
                continuation.resume(throwing: AuthError.invalidResponse)
            }
        }
    }

    private func extractAuthorizationCode(from url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.invalidResponse
        }
        return code
    }

    private func exchangeCodeForTokens(code: String, provider: CalendarProviderType) async throws -> OAuthCredentials {
        let config: (clientId: String, redirectUri: String, tokenEndpoint: String)

        switch provider {
        case .google:
            config = (GoogleConfig.clientId, GoogleConfig.redirectUri, GoogleConfig.tokenEndpoint)
        case .outlook:
            config = (MicrosoftConfig.clientId, MicrosoftConfig.redirectUri, MicrosoftConfig.tokenEndpoint)
        case .local:
            throw AuthError.invalidResponse
        }

        guard let tokenURL = URL(string: config.tokenEndpoint) else {
            throw AuthError.invalidResponse
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "client_id": config.clientId,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": config.redirectUri
        ]
        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError.tokenExchangeFailed(errorMessage)
        }

        struct TokenResponse: Decodable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int
        }

        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        return OAuthCredentials(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            expiresAt: Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in)),
            accountId: UUID().uuidString,
            providerType: provider
        )
    }
}

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentingWindow ?? NSApp.windows.first ?? NSWindow()
    }
}
