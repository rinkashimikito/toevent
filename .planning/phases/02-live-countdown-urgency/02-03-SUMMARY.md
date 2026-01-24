---
phase: 02-live-countdown-urgency
plan: 03
subsystem: calendar-priority
tags: [swift, calendar, userdefaults, drag-reorder, swiftui-list]

dependency-graph:
  requires: [01-core-menu-bar, 02-01]
  provides: [calendar-priority-storage, priority-based-event-selection, reorderable-calendar-ui]
  affects: [04-configuration]

tech-stack:
  added: []
  patterns: [userdefaults-array-persistence, computed-sorted-collection]

key-files:
  created: []
  modified:
    - ToEvent/ToEvent/State/AppState.swift
    - ToEvent/ToEvent/Services/CalendarService.swift
    - ToEvent/ToEvent/Views/Settings/CalendarSettingsView.swift

decisions:
  - id: flat-priority-list
    choice: "Flat reorderable list instead of grouped by source"
    reason: "Drag reordering requires flat list; source shown as secondary label preserves context"
  - id: priority-as-id-array
    choice: "Store calendar IDs in priority order array"
    reason: "Simple, efficient lookup via firstIndex; survives calendar renames"

metrics:
  duration: 4m
  completed: 2026-01-24
---

# Phase 2 Plan 3: Calendar Priority Summary

Calendar priority ordering for overlapping events. Users can reorder calendars in settings to control which event displays when multiple events start at the same time.

## What Was Built

### Task 1: Calendar Priority Storage in AppState
Added `calendarPriority: [String]` to AppState:
- Persisted to UserDefaults with key "calendarPriority"
- Loaded on app initialization
- First element = highest priority; lower index wins
- `initializeCalendarPriority(with:)` adds new calendars to end of list

### Task 2: Priority-Based Event Selection in CalendarService
Modified `fetchUpcomingEvents(from:lookahead:priority:)`:
- Added optional `priority: [String] = []` parameter (backward compatible)
- When events have the same start time, sorted by calendar priority index
- Calendars not in priority array treated as lowest priority (Int.max)

### Task 3: Reorderable Calendar List in Settings
Redesigned CalendarSettingsView:
- Changed from grouped-by-source layout to flat reorderable List
- `sortedCalendars` computed property orders by priority
- `.onMove(perform: moveCalendar)` enables drag-and-drop
- Reordering updates `appState.calendarPriority` and calls `refreshEvents()`
- Calendar source shown as secondary label in each row
- Calls `initializeCalendarPriority` on load to register any new calendars

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 630afca | feat | Add calendar priority storage to AppState |
| ca7d4bf | feat | Add priority parameter to fetchUpcomingEvents |
| fd31f6c | feat | Add calendar priority reordering to settings |

## Deviations from Plan

None - plan executed exactly as written.

## Technical Notes

- Priority stored as calendar IDs, not indices, so it survives calendar list changes
- Empty priority array or missing calendars default to Int.max (lowest priority)
- List style is `.inset` for consistent macOS appearance
- Fixed 300pt height prevents layout shifts as calendars are loaded
- Enable/disable toggle preserved from original implementation

## Next Phase Readiness

Phase 2 is complete. Phase 3 (Event Popover) can proceed.

**Blockers:** None
**Concerns:** None
