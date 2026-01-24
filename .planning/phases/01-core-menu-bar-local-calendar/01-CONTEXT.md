# Phase 1: Core Menu Bar + Local Calendar - Context

**Gathered:** 2026-01-24
**Status:** Ready for planning

<domain>
## Phase Boundary

MenuBarExtra presence with next event display from macOS Calendar. Includes calendar permissions and calendar selection. Does NOT include live countdown timer (Phase 2), dropdown event list (Phase 3), or external calendar APIs (Phase 5).

</domain>

<decisions>
## Implementation Decisions

### Menu bar display
- Show event title + relative time (e.g., "Standup in 45m")
- Truncate long titles with ellipsis at ~20-25 characters
- Calendar color indicator: colored dot before title
- Icon presence is a user setting (on/off toggle in settings)

### Calendar selection UX
- Settings live in a separate preferences window
- All calendars enabled by default (user opts out)
- Flat list of calendars with individual toggles
- No bulk enable/disable buttons

### Permission flow
- Request permission after brief intro screen (not immediately on launch)
- Intro explains value proposition: what app does and why calendar access is needed
- If permission denied: show instructions to enable in System Settings
- Include "Open Settings" button that deep-links to privacy settings

### Empty/edge states
- "All clear" text when no upcoming events (friendly tone)
- Lookahead window is configurable by user
- Default lookahead: 24 hours

### Claude's Discretion
- Exact wording of value proposition intro
- Visual design of settings window
- Error state handling for calendar sync failures
- Exact truncation character limit (around 20-25)

</decisions>

<specifics>
## Specific Ideas

- Relative time format fits Phase 1 scope (static/periodic update, not per-second countdown)
- "All clear" chosen for positive, friendly tone over "No events"
- Colored dot matches macOS Calendar app conventions

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope

</deferred>

---

*Phase: 01-core-menu-bar-local-calendar*
*Context gathered: 2026-01-24*
