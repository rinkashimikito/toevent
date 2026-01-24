---
phase: 05-external-calendar-apis
plan: 02
subsystem: auth
tags: [oauth, keychain, security, aswebauthenticationsession]
status: complete

dependency-graph:
  requires:
    - 05-01 (OAuthCredentials, CalendarProviderType, CalendarAccount models)
  provides:
    - KeychainService for secure token storage
    - AuthService for OAuth flow orchestration
    - toevent:// URL scheme for OAuth callbacks
  affects:
    - 05-03 (Google Calendar provider will use AuthService)
    - 05-04 (Microsoft Calendar provider will use AuthService)

tech-stack:
  added: []
  patterns:
    - ASWebAuthenticationSession for OAuth browser flow
    - Native Security framework for Keychain operations
    - Async/await token exchange

key-files:
  created:
    - ToEvent/ToEvent/Services/KeychainService.swift
    - ToEvent/ToEvent/Services/AuthService.swift
  modified:
    - ToEvent/ToEvent/ToEvent.entitlements
    - ToEvent/ToEvent/Info.plist
    - ToEvent/ToEvent.xcodeproj/project.pbxproj

decisions:
  - id: "05-02-01"
    choice: "Native Security framework over Valet"
    why: "Simpler, no external dependency, sufficient for OAuth token storage"
  - id: "05-02-02"
    choice: "Placeholder client IDs in source"
    why: "User must configure own OAuth credentials; prevents accidental key exposure"
  - id: "05-02-03"
    choice: "network.client entitlement added"
    why: "Required for OAuth token exchange HTTP requests in sandbox"

metrics:
  duration: 4m
  completed: 2026-01-24
---

# Phase 5 Plan 2: OAuth and Keychain Infrastructure Summary

OAuth authentication and secure token storage for external calendar providers.

## What Was Built

### KeychainService

Secure storage wrapper for OAuth credentials:

```swift
final class KeychainService {
    func save(_ credentials: OAuthCredentials, for accountId: String) throws
    func load(for accountId: String) -> OAuthCredentials?
    func delete(for accountId: String) throws
    func listAccountIds() -> [String]
}
```

- Uses `kSecClassGenericPassword` for token storage
- JSON encodes `OAuthCredentials` for persistence
- Handles update-on-duplicate via upsert pattern
- `KeychainError` enum for typed error handling

### AuthService

OAuth flow orchestration:

```swift
final class AuthService: NSObject, ObservableObject {
    func startOAuthFlow(for provider: CalendarProviderType, presentingWindow: NSWindow) async throws -> OAuthCredentials
    func loadStoredAccounts()
    func getCredentials(for accountId: String) -> OAuthCredentials?
    func deleteAccount(_ accountId: String) throws
}
```

- ASWebAuthenticationSession for system browser OAuth
- Builds auth URLs for Google and Microsoft
- Exchanges authorization code for tokens
- Persists credentials via KeychainService
- Publishes `@Published accounts: [CalendarAccount]`

### Entitlements and Configuration

**ToEvent.entitlements additions:**
- `keychain-access-groups` for token persistence
- `network.client` for OAuth token exchange

**Info.plist additions:**
- `CFBundleURLTypes` with `toevent://` scheme for OAuth callbacks

## Configuration Required

Before OAuth works, user must:

1. **Google Calendar API:**
   - Create OAuth 2.0 Client ID (iOS app type) in Google Cloud Console
   - Enable Google Calendar API
   - Replace `YOUR_GOOGLE_CLIENT_ID` in AuthService.swift

2. **Microsoft Graph API:**
   - Register application in Azure Portal
   - Add Calendars.Read permission
   - Replace `YOUR_MICROSOFT_CLIENT_ID` in AuthService.swift

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

Plan 05-03 (Google Calendar Provider) can now:
- Use `AuthService.shared.startOAuthFlow(for: .google, ...)` to authenticate
- Retrieve tokens via `AuthService.shared.getCredentials(for:)`
- Call Google Calendar API with access tokens

## Commits

| Hash | Description |
|------|-------------|
| 09c8dba | feat(05-02): add KeychainService for secure token storage |
| 50b93ef | feat(05-02): add AuthService with ASWebAuthenticationSession |
| 3f69504 | feat(05-02): add Keychain entitlement and OAuth URL scheme |
