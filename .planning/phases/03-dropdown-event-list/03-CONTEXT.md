# Phase 3: Dropdown Event List - Context

**Gathered:** 2026-01-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Clickable dropdown showing list of upcoming events with details. Users click menu bar to expand, see event list with times and calendar colors, click events to open in Calendar app, and access settings via bottom bar.

</domain>

<decisions>
## Implementation Decisions

### Event Row Layout
- Plain rows with dividers, not card-style (like Apple Reminders)
- Content is configurable; default is minimal (title + start time)
- Calendar color shown as subtle background tint on each row
- All-day events grouped at top, separate from timed events

### List Behavior
- Show all of today's remaining events by default
- Dropdown grows to fit content (no fixed height scroll)
- When no events today, fall back to showing tomorrow's events with date header
- Event lifecycle is configurable (remove at start, keep until end, or manual)

### Event Click Action
- Single click opens event in macOS Calendar app
- No secondary actions (no right-click menu, no hover preview)
- Visual feedback: highlight on hover + distinct pressed state

### Settings & Bottom Bar
- Fixed footer bar at bottom of dropdown
- Contains: gear icon (opens preferences) + refresh button (manual sync)
- Click gear opens existing preferences window (not inline settings)

### Claude's Discretion
- Keyboard navigation approach (arrow keys + Enter, or mouse-only)
- Quit action placement (bottom bar vs preferences-only)
- Exact row spacing and typography
- Date header styling for tomorrow fallback
- Loading/syncing state indicators

</decisions>

<specifics>
## Specific Ideas

- Row style should feel like Apple Reminders list items
- Background tint for calendar color should be subtle, not overwhelming
- Grow-to-fit means dropdown height varies with event count

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-dropdown-event-list*
*Context gathered: 2026-01-24*
