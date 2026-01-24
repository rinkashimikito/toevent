---
phase: 03-dropdown-event-list
plan: 02
subsystem: ui
tags: [swiftui, menubar, event-list, hover-state]

requires:
  - phase: 03-01
    provides: AppState with events array, allDayEvents, timedEvents computed properties

provides:
  - EventRowView with calendar color, title, time/countdown, hover states
  - EventListView with all-day grouping, tomorrow fallback, empty state
  - MenuBarView dropdown with full event list and footer bar

affects: [03-03, click-to-open, calendar-integration]

tech-stack:
  added: []
  patterns:
    - Custom ButtonStyle for row hover/pressed states
    - VStack-based list layout (not List) for menu bar popup
    - grow-to-fit dropdown via fixedSize

key-files:
  created:
    - ToEvent/ToEvent/Views/EventRowView.swift
    - ToEvent/ToEvent/Views/EventListView.swift
  modified:
    - ToEvent/ToEvent/Views/MenuBarView.swift

key-decisions:
  - "VStack over List for event rows (better menu bar popup styling)"
  - "Removed Quit button from footer (Cmd+Q exists, cleaner UI)"
  - "Calendar color tint on hover at 0.1 opacity"

patterns-established:
  - "EventRowButtonStyle: reusable button style with hover/pressed states and color tinting"
  - "grow-to-fit popup: .fixedSize(horizontal: false, vertical: true)"

duration: 4min
completed: 2026-01-24
---

# Phase 3 Plan 2: Event List UI Summary

**EventRowView with hover states, EventListView with all-day grouping and tomorrow fallback, MenuBarView footer with gear/refresh icons**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-24T20:06:00Z
- **Completed:** 2026-01-24T20:10:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Event rows show calendar color dot, title (truncated to 30 chars), time display
- Time display logic: "All day" for all-day events, countdown if within 1h, start time otherwise
- Custom ButtonStyle with subtle hover (calendar color tint) and pressed (accent color) states
- EventListView groups all-day events at top with divider separator
- Tomorrow fallback when no events today
- Empty state shows "All clear"
- Footer bar with gear (settings) and refresh icons
- Refresh button spins during refresh action

## Task Commits

1. **Task 1: Create EventRowView** - `ba3eb7f` (feat)
2. **Task 2: Create EventListView** - `a767031` (feat)
3. **Task 3: Update MenuBarView with EventListView and Footer** - `a8307c3` (feat)

## Files Created/Modified
- `ToEvent/ToEvent/Views/EventRowView.swift` - Single event row with hover state and calendar tint
- `ToEvent/ToEvent/Views/EventListView.swift` - VStack-based event list with grouping
- `ToEvent/ToEvent/Views/MenuBarView.swift` - Updated menu bar dropdown with event list and footer

## Decisions Made
- VStack over List for event rows - List styling conflicts with menu bar popup appearance
- Removed Quit button from footer - Cmd+Q standard exists, cleaner UI with just gear + refresh
- Calendar color tint at 0.1 opacity on hover - subtle but noticeable feedback
- Fixed 280px width with grow-to-fit vertical - consistent dropdown width, adapts to content

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- xcodebuild unavailable (developer tools path issue) - used swiftc -parse for syntax verification instead

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Event list UI complete with all grouping and states
- Ready for Plan 03: click-to-open Calendar.app integration
- openEventInCalendar placeholder in place for AppleScript implementation

---
*Phase: 03-dropdown-event-list*
*Completed: 2026-01-24*
