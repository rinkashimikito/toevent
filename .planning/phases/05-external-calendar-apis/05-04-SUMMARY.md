---
phase: 05-external-calendar-apis
plan: 04
subsystem: api
tags: [microsoft, graph-api, outlook, oauth]

dependency-graph:
  requires:
    - 05-01 (CalendarProvider protocol, models)
    - 05-02 (AuthService, KeychainService)
  provides:
    - OutlookCalendarProvider for Microsoft Graph API
    - MicrosoftAPIModels for JSON response parsing
  affects:
    - 05-05 (unified provider management)
    - Calendar settings UI (account display)

tech-stack:
  added: []
  patterns:
    - Microsoft Graph API v1.0 integration
    - Windows timezone mapping for date parsing
    - Microsoft color name to CGColor mapping

key-files:
  created:
    - ToEvent/ToEvent/Models/MicrosoftAPIModels.swift
    - ToEvent/ToEvent/Services/OutlookCalendarProvider.swift
  modified: []

decisions:
  - id: "05-04-01"
    choice: "Windows timezone name mapping table"
    why: "Microsoft Graph returns Windows-style timezone names (e.g., 'Pacific Standard Time') not IANA identifiers"
  - id: "05-04-02"
    choice: "Color name mapping to CGColor"
    why: "Microsoft returns color names ('lightBlue', 'lightGreen') not hex codes; mapped to reasonable CGColor values"
  - id: "05-04-03"
    choice: "URL-encode calendar IDs in path"
    why: "Calendar IDs may contain special characters; proper encoding prevents malformed URLs"

metrics:
  duration: 1m
  completed: 2026-01-24
---

# Phase 5 Plan 4: Outlook Calendar Provider Summary

OutlookCalendarProvider implementing CalendarProvider protocol with Microsoft Graph API integration, including Windows timezone mapping and Microsoft color name conversion.

## What Was Built

### MicrosoftAPIModels

Codable structs for Microsoft Graph API responses:

```swift
struct MicrosoftCalendarsResponse: Codable {
    let value: [MicrosoftCalendar]
}

struct MicrosoftCalendar: Codable {
    let id: String
    let name: String
    let color: String?
    let isDefaultCalendar: Bool?

    func toCalendarInfo(accountId:) -> CalendarInfo
}

struct MicrosoftEvent: Codable {
    let id: String
    let subject: String?
    let start: MicrosoftDateTime
    let end: MicrosoftDateTime
    let isAllDay: Bool?
    let isCancelled: Bool?

    func toEvent(...) -> Event
}

struct MicrosoftDateTime: Codable {
    let dateTime: String  // "2024-01-15T09:00:00.0000000"
    let timeZone: String  // "Pacific Standard Time"

    func toDate() -> Date?
}
```

Key features:
- Windows timezone name to IANA identifier mapping
- Microsoft color names to CGColor conversion
- Handles fractional seconds in datetime strings

### OutlookCalendarProvider

```swift
final class OutlookCalendarProvider: CalendarProvider {
    let providerType: CalendarProviderType = .outlook
    let account: CalendarAccount

    var isAuthenticated: Bool
    func authenticate(presentingWindow:) async throws
    func fetchCalendars() async throws -> [CalendarInfo]
    func fetchEvents(from:to:calendarIDs:) async throws -> [Event]
    func signOut() async
}
```

API endpoints used:
- `GET /me/calendars` - List all calendars
- `GET /me/calendars/{id}/calendarView?startDateTime=&endDateTime=` - Events in time range

Error handling:
- 401 -> OutlookCalendarError.authExpired
- 429 -> OutlookCalendarError.rateLimited (extracts Retry-After header)
- Network errors wrapped in .networkError

### OutlookCalendarError

```swift
enum OutlookCalendarError: Error {
    case noWindow
    case notAuthenticated
    case authExpired
    case rateLimited(retryAfter: Int?)
    case networkError(Error)
    case invalidResponse
}
```

## Commits

| Hash | Description |
|------|-------------|
| ba66f48 | feat(05-04): add Microsoft Graph API models |
| e879622 | feat(05-04): add OutlookCalendarProvider for Microsoft Graph |

## Deviations from Plan

None - plan executed exactly as written.

## Configuration Required

Before OutlookCalendarProvider works:

1. Register application in Azure Portal
2. Add Calendars.Read permission
3. Replace `YOUR_MICROSOFT_CLIENT_ID` in AuthService.swift

## Next Phase Readiness

- OutlookCalendarProvider ready for integration
- Follows same pattern as future GoogleCalendarProvider (05-03)
- Both providers use CalendarProvider protocol for unified handling
