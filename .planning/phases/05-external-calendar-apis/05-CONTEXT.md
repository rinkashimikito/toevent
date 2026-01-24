# Phase 5: External Calendar APIs - Context

**Gathered:** 2026-01-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Integrate Google Calendar and Outlook/Microsoft 365 via OAuth. External events appear alongside local EventKit events in menu bar and dropdown. Token storage in Keychain. Architecture supports adding other providers later.

</domain>

<decisions>
## Implementation Decisions

### Account management
- Add account UI lives within existing Calendars tab (not separate Accounts tab)
- Multiple accounts per provider supported (work + personal Google, etc.)
- "Add Account" button in Calendars tab triggers provider selection

### Auth experience
- OAuth flow happens in in-app webview (not system browser)
- When session/token expires, prompt user to re-login (not silent refresh)
- Login prompts should be non-intrusive but clear about which account needs re-auth

### Calendar mixing
- Flat list with labels in calendar selection UI
- Icon or badge indicates source (Google, Outlook, Local)
- No grouping by account — all calendars in single reorderable list
- Priority ordering works same as local calendars

### Sync behavior
- Offline: show cached events from last successful fetch
- External events cached locally for offline access

### Claude's Discretion
- Sync/fetch frequency for external APIs
- Staleness indicator design (if any)
- Exact webview implementation approach
- Cache storage format and invalidation strategy
- Error states and retry logic

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for OAuth and calendar API integration.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-external-calendar-apis*
*Context gathered: 2026-01-24*
