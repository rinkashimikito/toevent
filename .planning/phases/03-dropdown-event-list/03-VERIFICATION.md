---
phase: 03-dropdown-event-list
verified: 2026-01-24T21:35:00Z
status: human_needed
score: 7/7 must-haves verified
gaps: []
---

# Phase 3: Dropdown Event List Verification Report

**Phase Goal:** Clickable dropdown showing list of upcoming events with grow-to-fit layout
**Verified:** 2026-01-24T21:35:00Z
**Status:** human_needed
**Re-verification:** Yes - fixed grow-to-fit gap (commit 5e5f628)

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1   | User can click menu bar to expand dropdown | VERIFIED | `ToEventApp.swift:39-47` MenuBarExtra with `.menuBarExtraStyle(.window)` |
| 2   | User sees all upcoming events for today (or tomorrow if today empty) | VERIFIED | `EventListView.swift:10-14` with `todayContent`/`tomorrowContent` fallback logic |
| 3   | Each event displays title, time/countdown, and calendar color | VERIFIED | `EventRowView.swift:26-39` with Circle(calendarColor), truncatedTitle, timeDisplay |
| 4   | Dropdown grows to fit content (VStack-based, not scrollable) | VERIFIED | Fixed in 5e5f628 - removed `.frame(height: 200)` from ToEventApp.swift |
| 5   | User can click event to open in Calendar app | VERIFIED | `MenuBarView.swift:61-80` NSAppleScript + entitlements |
| 6   | Footer bar has gear icon and refresh button | VERIFIED | `MenuBarView.swift:20-39` footerBar with gear + arrow.clockwise |
| 7   | Events disappear from list after they start | VERIFIED | `AppState.swift:151-154` checks `event.startDate <= currentTime` then `refreshEvents()` |

**Score:** 7/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `ToEvent/ToEvent/Views/EventRowView.swift` | Event row component | VERIFIED | 85 lines, substantive, wired (used by EventListView) |
| `ToEvent/ToEvent/Views/EventListView.swift` | Event list component | VERIFIED | 90 lines, substantive, wired (used by MenuBarView) |
| `ToEvent/ToEvent/Views/MenuBarView.swift` | Menu dropdown view | VERIFIED | 82 lines, substantive, wired (used by ToEventApp) |
| `ToEvent/ToEvent/State/AppState.swift` | events array | VERIFIED | Line 17: `@Published private(set) var events: [Event] = []` |
| `ToEvent/ToEvent/Models/Event.swift` | calendarTitle property | VERIFIED | Line 12: `let calendarTitle: String`, line 42: from EKEvent |
| `ToEvent/ToEvent/ToEvent.entitlements` | AppleScript entitlement | VERIFIED | Line 9: `com.apple.security.automation.apple-events` |
| `ToEvent/ToEvent/Info.plist` | Usage description | VERIFIED | Line 12: `NSAppleEventsUsageDescription` |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| EventRowView | Event tap handler | Button(action: onTap) | WIRED | EventRowView.swift:16 |
| EventListView | onEventTap closure | EventRowView(onTap:) | WIRED | EventListView.swift:27, 34 |
| MenuBarView | openEventInCalendar | EventListView(onEventTap:) | WIRED | MenuBarView.swift:10 |
| openEventInCalendar | Calendar.app | NSAppleScript | WIRED | MenuBarView.swift:61-80 |
| AppState.events | EventListView | appState.events | WIRED | EventListView.swift:8 |
| tickCountdown | refreshEvents | Event expiry check | WIRED | AppState.swift:151-154 |

### Requirements Coverage

Based on ROADMAP.md requirement references (DROP-01 through DROP-07):

| Requirement | Status |
| ----------- | ------ |
| DROP-01: Clickable dropdown | SATISFIED |
| DROP-02: Today's events (tomorrow fallback) | SATISFIED |
| DROP-03: Event display (title, time, color) | SATISFIED |
| DROP-04: Grow-to-fit layout | SATISFIED |
| DROP-05: Click to open Calendar | SATISFIED |
| DROP-06: Footer bar (gear + refresh) | SATISFIED |
| DROP-07: Events expire after start | SATISFIED |

### Human Verification Required

1. **AppleScript Calendar Integration**
   - **Test:** Click an event row in the dropdown
   - **Expected:** Calendar.app opens and navigates to/shows that specific event
   - **Why human:** AppleScript execution success depends on macOS permissions prompt and Calendar.app state

2. **Visual Appearance**
   - **Test:** Open dropdown and review event list styling
   - **Expected:** Calendar color dots visible, text readable, hover/pressed states work
   - **Why human:** Visual correctness cannot be programmatically verified

3. **Tomorrow Fallback**
   - **Test:** When no events exist for today, check if tomorrow's events appear
   - **Expected:** "Tomorrow" header shown with tomorrow's events
   - **Why human:** Requires specific calendar state to test

4. **Grow-to-fit Behavior**
   - **Test:** Add/remove events and observe dropdown height changes
   - **Expected:** Dropdown height adjusts to content, no scrollbar appears
   - **Why human:** Visual verification needed to confirm fix works

---

*Verified: 2026-01-24T21:35:00Z*
*Verifier: Claude (gsd-verifier)*
*Re-verified after orchestrator fix*
