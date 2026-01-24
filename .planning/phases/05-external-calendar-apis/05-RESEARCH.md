# Phase 5: External Calendar APIs - Research

**Researched:** 2026-01-24
**Domain:** OAuth 2.0, Google Calendar API, Microsoft Graph API, Keychain storage
**Confidence:** MEDIUM (verified with official docs, some gaps in macOS-specific patterns)

## Summary

This phase integrates Google Calendar and Microsoft Outlook via OAuth 2.0 authentication and REST APIs. The research reveals a critical constraint: **Google blocks OAuth in embedded webviews (WKWebView)**. The CONTEXT.md decision for "in-app webview" cannot be honored for Google accounts - browser-based auth is mandatory per Google's security policy.

Both calendar services expose REST APIs for fetching events. The architecture should define a `CalendarProvider` protocol that abstracts the data source, allowing EventKit, Google, and Microsoft to be treated uniformly. Token storage uses macOS Keychain via a wrapper library for security.

**Primary recommendation:** Use ASWebAuthenticationSession (or AppAuth-iOS with loopback HTTP) for OAuth. Store tokens in Keychain via Valet. Define a protocol-based provider architecture for extensibility.

## Critical: OAuth WebView Restriction

**CONTEXT.md states:** "OAuth flow happens in in-app webview (not system browser)"

**Google's policy (enforced since 2021):**
> "This user-agent is not permitted to make OAuth authorisation request to Google as it is classified as an embedded user-agent."

**Implication:** The user's preference for in-app webview cannot be implemented for Google. Options:
1. Use ASWebAuthenticationSession (system browser sheet) for both Google and Microsoft
2. Use different flows per provider (system browser for Google, webview for Microsoft)

**Recommendation:** Use ASWebAuthenticationSession for both providers. This is the standard approach and provides consistent UX. The session appears as an in-app sheet, not a full browser redirect.

Source: [Google OAuth 2.0 for Native Apps](https://developers.google.com/identity/protocols/oauth2/native-app)

## Standard Stack

The established libraries and tools for this domain:

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AuthenticationServices | System | ASWebAuthenticationSession for OAuth | Apple-provided, secure browser-based OAuth |
| GoogleSignIn-iOS | 8.x | Google Sign-In SDK | Official Google SDK, handles token management |
| MSAL | 2.7.x | Microsoft Auth Library | Official MS SDK, handles token management |
| Valet | 5.x | Keychain wrapper | Square-maintained, thread-safe, clean API |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AppAuth-iOS | 1.3.x | Generic OAuth client | Alternative to vendor SDKs, more control |
| KeychainSwift | 22.x | Simpler Keychain wrapper | If Valet is overkill |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| GoogleSignIn-iOS | Raw OAuth via AppAuth | More control, but lose Google's token management |
| MSAL | Raw OAuth via AppAuth | More control, but lose Microsoft's token management |
| Valet | Native Security framework | Zero dependencies, but verbose C-based API |

**Installation:**
```bash
# Swift Package Manager dependencies
https://github.com/google/GoogleSignIn-iOS.git
https://github.com/AzureAD/microsoft-authentication-library-for-objc.git
https://github.com/Square/Valet.git
```

## Architecture Patterns

### Recommended Project Structure
```
ToEvent/
├── Services/
│   ├── CalendarService.swift       # Existing EventKit service
│   ├── CalendarProviderProtocol.swift  # Provider abstraction
│   ├── LocalCalendarProvider.swift     # EventKit implementation
│   ├── GoogleCalendarProvider.swift    # Google API implementation
│   ├── OutlookCalendarProvider.swift   # Microsoft Graph implementation
│   └── AuthService.swift               # Centralized OAuth handling
├── Models/
│   ├── Event.swift                 # Existing, add source property
│   ├── CalendarInfo.swift          # Existing, add provider type
│   ├── CalendarAccount.swift       # NEW: account model
│   └── OAuthCredentials.swift      # NEW: token storage model
├── State/
│   └── AppState.swift              # Extended for multi-provider
└── Views/
    └── Settings/
        └── CalendarSettingsView.swift  # Extended for accounts
```

### Pattern 1: Protocol-Based Calendar Provider

**What:** Abstract calendar data fetching behind a protocol
**When to use:** Always - this is the extensibility foundation

```swift
// Source: Protocol-Oriented Programming pattern
protocol CalendarProvider {
    var providerType: CalendarProviderType { get }
    var isAuthenticated: Bool { get }

    func authenticate() async throws
    func fetchEvents(from: Date, to: Date) async throws -> [Event]
    func fetchCalendars() async throws -> [CalendarInfo]
    func refreshTokenIfNeeded() async throws
}

enum CalendarProviderType: String, Codable {
    case local
    case google
    case outlook
}
```

### Pattern 2: Centralized Auth Service

**What:** Single service managing all OAuth flows and token storage
**When to use:** To avoid duplicating auth logic across providers

```swift
// Source: Standard OAuth management pattern
final class AuthService {
    private let valet: Valet

    func startOAuthFlow(
        for provider: CalendarProviderType,
        presentingWindow: NSWindow
    ) async throws -> OAuthCredentials

    func loadCredentials(for provider: CalendarProviderType, accountId: String) -> OAuthCredentials?
    func saveCredentials(_ credentials: OAuthCredentials, for accountId: String)
    func deleteCredentials(for accountId: String)
}
```

### Pattern 3: Event Source Tracking

**What:** Track which provider each event came from
**When to use:** For UI display (icons/badges) and cache management

```swift
// Extend existing Event model
struct Event: Identifiable {
    // ... existing properties
    let source: CalendarProviderType  // NEW
    let accountId: String?            // NEW: for external events
}
```

### Anti-Patterns to Avoid

- **Storing tokens in UserDefaults:** Security vulnerability. Always use Keychain.
- **Implementing OAuth manually:** Use vendor SDKs or AppAuth. OAuth is complex with many edge cases.
- **Polling at fixed intervals:** Respect rate limits. Use exponential backoff on errors.
- **Single monolithic CalendarService:** Breaks extensibility. Use protocol-based providers.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| OAuth 2.0 flow | Custom URL handling | GoogleSignIn-iOS, MSAL | PKCE, token refresh, error handling |
| Token storage | UserDefaults wrapper | Valet or KeychainSwift | Keychain has C-based API, thread-safety issues |
| Token refresh | Manual timer | Vendor SDKs handle this | Complex expiry logic, race conditions |
| HTTP requests to APIs | Raw URLSession | Vendor SDKs | Auth header injection, retry logic |

**Key insight:** OAuth looks simple (redirect, get token) but has many edge cases: PKCE, token refresh, concurrent requests, revocation, cross-device state. Vendor SDKs handle these.

## Common Pitfalls

### Pitfall 1: Google WKWebView Block

**What goes wrong:** OAuth fails with "user-agent not permitted" error
**Why it happens:** Google banned embedded webviews for OAuth in 2021
**How to avoid:** Use ASWebAuthenticationSession or GoogleSignIn-iOS SDK
**Warning signs:** 403 error during OAuth, error mentioning "embedded user-agent"

### Pitfall 2: Token Expiry Without Refresh

**What goes wrong:** App works initially, fails after 1 hour (Google) or varies (Microsoft)
**Why it happens:** Access tokens expire, refresh logic not implemented
**How to avoid:** Use vendor SDKs which handle refresh automatically, or implement proper refresh with MSAL/GoogleSignIn callbacks
**Warning signs:** 401 errors after app has been running for a while

### Pitfall 3: Keychain Entitlement Missing on macOS

**What goes wrong:** Valet/Keychain writes fail silently or crash
**Why it happens:** macOS requires Keychain Sharing entitlement even for single-app use
**How to avoid:** Add Keychain Sharing entitlement in Xcode
**Warning signs:** `errSecMissingEntitlement` errors, empty reads from Keychain

### Pitfall 4: Rate Limiting Without Backoff

**What goes wrong:** 429 errors, temporary bans from APIs
**Why it happens:** Burst requests during sync or startup
**How to avoid:** Implement exponential backoff, respect Retry-After headers
**Warning signs:** 429 Too Many Requests, 403 usageLimits errors

### Pitfall 5: Concurrent Token Refresh

**What goes wrong:** Multiple refresh requests fire, one invalidates others
**Why it happens:** Async code triggers refresh from multiple places simultaneously
**How to avoid:** Use a token refresh lock/semaphore, or rely on SDK's built-in handling
**Warning signs:** Intermittent auth failures, "invalid_grant" errors

## API Reference

### Google Calendar API v3

**Base URL:** `https://www.googleapis.com/calendar/v3`

**List Calendars:**
```
GET /users/me/calendarList
Authorization: Bearer {access_token}
```

**List Events:**
```
GET /calendars/{calendarId}/events
  ?timeMin={RFC3339}
  &timeMax={RFC3339}
  &singleEvents=true
  &orderBy=startTime
Authorization: Bearer {access_token}
```

**Required Scope (read-only):** `https://www.googleapis.com/auth/calendar.readonly`

**Rate Limits:**
- 1,000,000 queries/day (project)
- Per-minute limits enforced (undocumented exact values)
- Handle 403/429 with exponential backoff

Source: [Google Calendar API Reference](https://developers.google.com/calendar/api/v3/reference)

### Microsoft Graph API

**Base URL:** `https://graph.microsoft.com/v1.0`

**List Calendars:**
```
GET /me/calendars
Authorization: Bearer {access_token}
```

**List Events (Calendar View for time range):**
```
GET /me/calendar/calendarView
  ?startDateTime={ISO8601}
  &endDateTime={ISO8601}
Authorization: Bearer {access_token}
```

**Required Scope:** `Calendars.Read` or `Calendars.ReadBasic`

**Rate Limits:**
- 10,000 requests per 10 minutes per app per mailbox
- Global: 130,000 requests per 10 seconds per app
- Handle 429 with Retry-After header

Source: [Microsoft Graph Calendar API](https://learn.microsoft.com/en-us/graph/api/calendar-list-events)

## Code Examples

### ASWebAuthenticationSession for OAuth

```swift
// Source: Apple AuthenticationServices documentation
import AuthenticationServices

class AuthenticationCoordinator: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var window: NSWindow?

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        window ?? NSApp.windows.first!
    }

    func authenticate(
        authURL: URL,
        callbackScheme: String,
        window: NSWindow
    ) async throws -> URL {
        self.window = window

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let callbackURL = callbackURL {
                    continuation.resume(returning: callbackURL)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
}
```

### Valet Keychain Storage

```swift
// Source: Square Valet documentation
import Valet

struct TokenStorage {
    private let valet = Valet.valet(
        with: Identifier(nonEmpty: "com.toevent.oauth")!,
        accessibility: .whenUnlocked
    )

    func saveTokens(_ tokens: OAuthCredentials, for accountId: String) throws {
        let data = try JSONEncoder().encode(tokens)
        try valet.setObject(data, forKey: accountId)
    }

    func loadTokens(for accountId: String) -> OAuthCredentials? {
        guard let data = try? valet.object(forKey: accountId) else { return nil }
        return try? JSONDecoder().decode(OAuthCredentials.self, from: data)
    }

    func deleteTokens(for accountId: String) {
        try? valet.removeObject(forKey: accountId)
    }
}

struct OAuthCredentials: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresAt: Date
    let accountId: String
    let providerType: CalendarProviderType
}
```

### Google Calendar Event Fetch

```swift
// Source: Google Calendar API v3 documentation
func fetchGoogleEvents(
    accessToken: String,
    calendarId: String,
    from: Date,
    to: Date
) async throws -> [Event] {
    var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!
    components.queryItems = [
        URLQueryItem(name: "timeMin", value: ISO8601DateFormatter().string(from: from)),
        URLQueryItem(name: "timeMax", value: ISO8601DateFormatter().string(from: to)),
        URLQueryItem(name: "singleEvents", value: "true"),
        URLQueryItem(name: "orderBy", value: "startTime")
    ]

    var request = URLRequest(url: components.url!)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw CalendarError.invalidResponse
    }

    switch httpResponse.statusCode {
    case 200:
        let result = try JSONDecoder().decode(GoogleEventsResponse.self, from: data)
        return result.items.map { Event(from: $0, source: .google) }
    case 401:
        throw CalendarError.unauthorized
    case 429, 403:
        throw CalendarError.rateLimited
    default:
        throw CalendarError.apiError(httpResponse.statusCode)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| WKWebView OAuth | ASWebAuthenticationSession | 2019 (iOS 13) | Required for Google |
| Manual token refresh | SDK-managed refresh | Ongoing | Reduces auth failures |
| UserDefaults tokens | Keychain storage | Always best practice | Security requirement |
| ADAL (Azure) | MSAL | 2020 | ADAL deprecated |

**Deprecated/outdated:**
- **UIWebView/WKWebView for OAuth:** Blocked by Google, discouraged by Apple
- **ADAL (Azure AD Authentication Library):** Replaced by MSAL
- **Basic authentication for Google:** Disabled March 2025

## Open Questions

Things that couldn't be fully resolved:

1. **Token refresh on session expiry**
   - What we know: CONTEXT.md says "prompt user to re-login" not silent refresh
   - What's unclear: Should this be per-account or when any account expires?
   - Recommendation: Implement per-account prompts in settings UI

2. **Sync frequency for external APIs**
   - What we know: CONTEXT.md marks this as Claude's discretion
   - What's unclear: Optimal balance between freshness and API quota
   - Recommendation: 5-minute default, configurable, with manual refresh button

3. **Cache storage format**
   - What we know: Need to cache events for offline access
   - What's unclear: SQLite vs JSON files vs Core Data
   - Recommendation: Simple JSON files per account (events are small, infrequent writes)

4. **Multiple accounts same provider**
   - What we know: CONTEXT.md confirms multiple Google accounts supported
   - What's unclear: How vendor SDKs handle multiple accounts
   - Recommendation: Test with GoogleSignIn-iOS multi-account flow, may need custom account management

## Sources

### Primary (HIGH confidence)
- [Google Calendar API v3 Reference](https://developers.google.com/calendar/api/v3/reference) - Endpoints, parameters, scopes
- [Microsoft Graph Calendar API](https://learn.microsoft.com/en-us/graph/api/calendar-list-events) - Endpoints, permissions, response format
- [Google OAuth 2.0 for Native Apps](https://developers.google.com/identity/protocols/oauth2/native-app) - WKWebView restriction
- [MSAL for iOS/macOS](https://github.com/AzureAD/microsoft-authentication-library-for-objc) - Installation, usage pattern
- [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) - Installation, macOS support
- [Valet](https://github.com/square/Valet) - Keychain wrapper for macOS

### Secondary (MEDIUM confidence)
- [AppAuth-iOS](https://github.com/openid/AppAuth-iOS) - Generic OAuth, macOS loopback handling
- [Google Calendar API Quotas](https://developers.google.com/workspace/calendar/api/guides/quota) - Rate limiting
- [Microsoft Graph Throttling](https://learn.microsoft.com/en-us/graph/throttling) - Rate limiting

### Tertiary (LOW confidence)
- WebSearch results on OAuth patterns - General guidance, needs validation
- WebSearch results on Keychain best practices - Aligned with official docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official vendor SDKs well-documented
- Architecture: MEDIUM - Protocol pattern is standard, but macOS-specific OAuth less documented
- API usage: HIGH - Official REST API docs are authoritative
- Rate limits: MEDIUM - Google has undocumented limits, Microsoft is clearer
- Pitfalls: MEDIUM - Based on community reports and official warnings

**Research date:** 2026-01-24
**Valid until:** 2026-02-24 (30 days - OAuth and APIs are stable)

**Critical finding for orchestrator:** User's CONTEXT.md decision for "in-app webview" conflicts with Google's security policy. Recommend ASWebAuthenticationSession (appears as sheet, not full browser redirect) as compromise. This should be confirmed with user before planning.
