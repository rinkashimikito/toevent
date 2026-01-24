---
phase: 05-external-calendar-apis
verified: 2026-01-24T22:30:00Z
status: passed
score: 6/6 must-haves verified
re_verification: false
human_verification:
  - test: "Add Google Calendar account"
    expected: "OAuth flow opens in browser, returns to app, calendars appear"
    why_human: "Requires real OAuth credentials configured in AuthService"
  - test: "Add Microsoft Outlook account"
    expected: "OAuth flow opens in browser, returns to app, calendars appear"
    why_human: "Requires real OAuth credentials configured in AuthService"
  - test: "Events from external calendars appear in menu bar"
    expected: "After adding account, external calendar events show in dropdown with source icons"
    why_human: "Requires live OAuth connection to verify data flow end-to-end"
  - test: "Token expiry re-auth prompt"
    expected: "When token expires, re-auth warning appears in settings"
    why_human: "Requires waiting for token expiry or manual token invalidation"
---

# Phase 5: External Calendar APIs Verification Report

**Phase Goal:** Google Calendar and Outlook integration via OAuth using ASWebAuthenticationSession
**Verified:** 2026-01-24T22:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can authenticate with Google Calendar via OAuth | VERIFIED | AuthService.swift:56-86 implements startOAuthFlow with ASWebAuthenticationSession, GoogleConfig has auth/token endpoints, AddAccountSheet triggers flow for .google |
| 2 | User can authenticate with Outlook/Microsoft 365 via OAuth | VERIFIED | AuthService.swift uses MicrosoftConfig with Graph API endpoints, OutlookCalendarProvider.authenticate() calls AuthService.startOAuthFlow for .outlook |
| 3 | Events from external calendars appear in menu bar and dropdown | VERIFIED | AppState.refreshEvents() delegates to CalendarProviderManager.fetchAllEvents(), which iterates all providers including Google/Outlook; events sorted and displayed |
| 4 | OAuth tokens are stored securely in Keychain | VERIFIED | KeychainService.swift (103 lines) uses Security framework with kSecClassGenericPassword, save/load/delete methods implemented, AuthService calls keychainService.save() |
| 5 | Token expiry prompts user to re-authenticate | VERIFIED | CalendarProviderManager tracks expiredAccounts, CalendarSettingsView displays re-auth warning section with "Sign In" button, reauthenticate() method calls AuthService |
| 6 | Architecture supports adding other calendar sources | VERIFIED | CalendarProvider protocol defines contract, CalendarProviderType enum extensible, CalendarProviderManager dynamically adds providers by type |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ToEvent/ToEvent/Models/CalendarProviderType.swift` | Provider type enum | VERIFIED | 29 lines, enum with local/google/outlook, displayName/symbolName computed |
| `ToEvent/ToEvent/Models/CalendarAccount.swift` | Account model | VERIFIED | 15 lines, Codable struct with static .local singleton |
| `ToEvent/ToEvent/Models/OAuthCredentials.swift` | Token model | VERIFIED | 17 lines, Codable with isExpired/needsRefresh computed |
| `ToEvent/ToEvent/Services/CalendarProviderProtocol.swift` | Provider contract | VERIFIED | 12 lines, protocol with authenticate/fetchEvents/fetchCalendars/signOut |
| `ToEvent/ToEvent/Services/LocalCalendarProvider.swift` | EventKit wrapper | VERIFIED | 37 lines, delegates to CalendarService, handles macOS 13/14 auth |
| `ToEvent/ToEvent/Services/KeychainService.swift` | Keychain wrapper | VERIFIED | 103 lines, save/load/delete/listAccountIds with Security framework |
| `ToEvent/ToEvent/Services/AuthService.swift` | OAuth orchestration | VERIFIED | 250 lines, ASWebAuthenticationSession, token exchange, account management |
| `ToEvent/ToEvent/Services/GoogleCalendarProvider.swift` | Google Calendar API | VERIFIED | 186 lines, implements CalendarProvider, uses googleapis.com/calendar/v3 |
| `ToEvent/ToEvent/Services/OutlookCalendarProvider.swift` | Microsoft Graph API | VERIFIED | 149 lines, implements CalendarProvider, uses graph.microsoft.com/v1.0 |
| `ToEvent/ToEvent/Services/CalendarProviderManager.swift` | Multi-provider aggregation | VERIFIED | 141 lines, fetchAllEvents/fetchAllCalendars, expiredAccounts tracking |
| `ToEvent/ToEvent/Services/EventCacheService.swift` | Offline cache | VERIFIED | 153 lines, JSON file per account, CodableEvent wrapper, CGColor hex encoding |
| `ToEvent/ToEvent/Models/GoogleAPIModels.swift` | Google API Codable | VERIFIED | 118 lines, GoogleCalendarsResponse/GoogleEventsResponse/GoogleEvent with toEvent conversion |
| `ToEvent/ToEvent/Models/MicrosoftAPIModels.swift` | Microsoft API Codable | VERIFIED | 146 lines, MicrosoftCalendarsResponse/MicrosoftEventsResponse with timezone mapping |
| `ToEvent/ToEvent/Views/Settings/AddAccountSheet.swift` | OAuth trigger UI | VERIFIED | 84 lines, Google/Outlook buttons, calls AuthService.startOAuthFlow |
| `ToEvent/ToEvent/Views/Settings/CalendarSettingsView.swift` | Account management UI | VERIFIED | 247 lines, Add Account button, source icons, re-auth warning, remove accounts |
| `ToEvent/ToEvent/Models/Event.swift` | Event with source | VERIFIED | 52 lines, has source: CalendarProviderType and accountId: String? properties |
| `ToEvent/ToEvent/Models/CalendarInfo.swift` | CalendarInfo with provider | VERIFIED | 36 lines, has providerType and accountId properties |
| `ToEvent/ToEvent/ToEvent.entitlements` | Entitlements | VERIFIED | Has com.apple.security.network.client for OAuth requests |
| `ToEvent/ToEvent/Info.plist` | URL scheme | VERIFIED | CFBundleURLSchemes with "toevent" for OAuth callback |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| AuthService.swift | ASWebAuthenticationSession | import AuthenticationServices | WIRED | Line 1: import, Line 146: creates session |
| AuthService.swift | KeychainService | token persistence | WIRED | Line 49: keychainService property, Line 71: save(), Line 89: load() |
| GoogleCalendarProvider | googleapis.com/calendar/v3 | URLSession | WIRED | Line 38: baseURL, Line 161: request() builds URL and makes request |
| GoogleCalendarProvider | AuthService | credential retrieval | WIRED | Line 42: getCredentials(), Line 54: startOAuthFlow() |
| OutlookCalendarProvider | graph.microsoft.com/v1.0 | URLSession | WIRED | Line 38: baseURL, request() method makes API calls |
| OutlookCalendarProvider | AuthService | credential retrieval | WIRED | Line 42: getCredentials(), Line 53: startOAuthFlow() |
| AppState | CalendarProviderManager | refreshEvents() delegation | WIRED | Line 311: fetchAllEvents() called |
| CalendarSettingsView | AuthService | OAuth flow trigger | WIRED | Line 62: startOAuthFlow in AddAccountSheet, Line 227: in reauthenticate() |
| CalendarSettingsView | CalendarProviderManager | calendar list source | WIRED | Line 5: @ObservedObject, Line 77: addProvider, Line 204: fetchAllCalendars |
| Event.swift | CalendarProviderType | source property | WIRED | Line 13: source property, Line 36: default .local |
| CalendarInfo.swift | CalendarProviderType | providerType property | WIRED | Line 9: providerType property, Line 18: default .local |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| CALD-04: Google Calendar API integration | SATISFIED | - |
| CALD-05: Microsoft/Outlook API integration | SATISFIED | - |
| CALD-06: Secure token storage | SATISFIED | Keychain with Security framework |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| AuthService.swift | 28,36 | `YOUR_GOOGLE_CLIENT_ID`, `YOUR_MICROSOFT_CLIENT_ID` | Info | Expected - user must configure own OAuth credentials |
| CalendarProviderManager.swift | 103 | `continue` on error | Info | Intentional - skip failed calendars, continue with others |
| EventCacheService.swift | 125 | `print("Cache for...")` | Info | Debug logging for stale cache, not blocking |

No blocking anti-patterns found. Placeholder client IDs are intentional for user configuration.

### Human Verification Required

1. **Add Google Calendar account**
   - **Test:** Open Settings > Calendars, click "Add Account", select "Google Calendar"
   - **Expected:** Browser OAuth flow opens, user authenticates, returns to app, Google calendars appear in list with "g.circle" icon
   - **Why human:** Requires real Google OAuth Client ID configured in AuthService.swift

2. **Add Microsoft Outlook account**
   - **Test:** Open Settings > Calendars, click "Add Account", select "Microsoft Outlook"
   - **Expected:** Browser OAuth flow opens, user authenticates, returns to app, Microsoft calendars appear in list with "m.circle" icon
   - **Why human:** Requires real Microsoft Client ID configured in AuthService.swift

3. **Events from external calendars in menu bar**
   - **Test:** After adding external account, check menu bar dropdown
   - **Expected:** Events from external calendar appear alongside local events, sorted by start time
   - **Why human:** Requires live OAuth connection to fetch real event data

4. **Token expiry re-authentication**
   - **Test:** Wait for token to expire or manually invalidate
   - **Expected:** Re-auth warning appears in Settings > Calendars with "Sign In" button
   - **Why human:** Requires token expiration scenario

### Gaps Summary

No gaps found. All Phase 5 success criteria are met at the code level.

The implementation is complete and structurally verified:
- OAuth flow infrastructure is fully implemented with ASWebAuthenticationSession
- Keychain storage is properly wired for secure token persistence
- Google Calendar API provider fetches calendars and events with proper error handling
- Microsoft Graph API provider fetches calendars and events with timezone/color mapping
- Multi-provider aggregation works through CalendarProviderManager
- Event caching provides offline fallback
- UI supports adding/removing accounts and re-authentication prompts
- Event and CalendarInfo models track their source provider

Human verification is required to test the live OAuth flows with configured credentials.

---

*Verified: 2026-01-24T22:30:00Z*
*Verifier: Claude (gsd-verifier)*
