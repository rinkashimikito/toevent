# Roadmap: ToEvent

## Overview

ToEvent is a macOS menu bar app that displays upcoming calendar events with a live countdown timer. The journey begins with core menu bar presence and local calendar integration (Phase 1), adds the differentiating live countdown with urgency indicators (Phase 2), expands to a full dropdown event list (Phase 3), polishes the experience with launch essentials (Phase 4), integrates external calendar APIs (Phase 5), adds high-value meeting and notification features (Phase 6), and concludes with distribution and notarization for public release (Phase 7).

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Core Menu Bar + Local Calendar** - MenuBarExtra foundation with EventKit integration
- [x] **Phase 2: Live Countdown + Urgency** - Real-time countdown with color-coded warnings
- [x] **Phase 3: Dropdown Event List** - Full event list UI with scrolling
- [x] **Phase 4: Polish + Launch Essentials** - Auto-launch, keyboard shortcuts, settings
- [x] **Phase 5: External Calendar APIs** - Google Calendar and Outlook integration
- [x] **Phase 6: Meeting Links + Notifications** - One-click join and event reminders
- [ ] **Phase 7: Distribution + Notarization** - Code signing and public release

## Phase Details

### Phase 1: Core Menu Bar + Local Calendar
**Goal**: MenuBarExtra presence with next event display from macOS Calendar
**Depends on**: Nothing (first phase)
**Requirements**: CALD-01, CALD-02, CALD-03, CALD-07, CALD-09, MENU-01, MENU-05
**Success Criteria** (what must be TRUE):
  1. User can grant calendar permissions when prompted
  2. User sees next upcoming event title in menu bar
  3. User can select which calendars to show
  4. All-day events display as "Today" instead of countdown
  5. Menu bar respects light and dark mode
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Xcode project foundation + CalendarService
- [x] 01-02-PLAN.md — Menu bar display + intro/permission flow
- [x] 01-03-PLAN.md — Calendar settings with preferences window

### Phase 2: Live Countdown + Urgency
**Goal**: Real-time countdown in menu bar with color-coded urgency indicators
**Depends on**: Phase 1
**Requirements**: MENU-02, MENU-03, MENU-04, CALD-08
**Success Criteria** (what must be TRUE):
  1. User sees countdown timer updating every second in menu bar
  2. Menu bar text changes color based on time remaining (yellow at 1h, orange at 30m, red at 15m)
  3. Menu bar icon changes based on urgency level
  4. Calendar events show their associated calendar color
  5. Battery impact remains minimal (validated via Activity Monitor)
**Plans**: 3 plans

Plans:
- [x] 02-01-PLAN.md — Urgency infrastructure (UrgencyLevel enum, hybrid formatter, screen lock service)
- [x] 02-02-PLAN.md — Live countdown with colored text (MenuBarExtraAccess, adaptive updates)
- [x] 02-03-PLAN.md — Calendar priority for overlapping events (reorderable settings)

### Phase 3: Dropdown Event List
**Goal**: Clickable dropdown showing list of upcoming events with grow-to-fit layout
**Depends on**: Phase 2
**Requirements**: DROP-01, DROP-02, DROP-03, DROP-04, DROP-05, DROP-06, DROP-07
**Success Criteria** (what must be TRUE):
  1. User can click menu bar to expand dropdown
  2. User sees all upcoming events for today (or tomorrow if today empty)
  3. Each event displays title, time/countdown, and calendar color
  4. Dropdown grows to fit content (VStack-based, not scrollable)
  5. User can click event to open in Calendar app
  6. Footer bar has gear icon and refresh button
  7. Events disappear from list after they start
**Plans**: 3 plans

Plans:
- [x] 03-01-PLAN.md — Event list data layer (AppState.events, Event.calendarTitle)
- [x] 03-02-PLAN.md — Event list UI (EventRowView, EventListView, updated MenuBarView)
- [x] 03-03-PLAN.md — Open event in Calendar (AppleScript integration, entitlements)

### Phase 4: Polish + Launch Essentials
**Goal**: Auto-launch, keyboard shortcuts, and customization settings
**Depends on**: Phase 3
**Requirements**: SYST-01, SYST-02, CUST-03, CUST-04, CUST-05, CUST-06, MENU-06, MENU-07, SYST-05
**Success Criteria** (what must be TRUE):
  1. User can set global keyboard shortcut to toggle dropdown
  2. App auto-launches at login (configurable)
  3. User can customize color thresholds for urgency warnings
  4. User can choose time display format (countdown, absolute, or both)
  5. User can choose natural language vs precise times ("soon" vs "in 5min")
  6. User can enable privacy mode to hide event titles
  7. User can set calendar fetch interval
  8. User can configure number of events shown in dropdown
  9. Battery optimization settings are available
**Plans**: 3 plans

Plans:
- [x] 04-01-PLAN.md — System integration (keyboard shortcut + auto-launch)
- [x] 04-02-PLAN.md — Display settings (time format, privacy, natural language)
- [x] 04-03-PLAN.md — Advanced settings (thresholds, fetch interval, event count, battery)

### Phase 5: External Calendar APIs
**Goal**: Google Calendar and Outlook integration via OAuth using ASWebAuthenticationSession
**Depends on**: Phase 4
**Requirements**: CALD-04, CALD-05, CALD-06
**Success Criteria** (what must be TRUE):
  1. User can authenticate with Google Calendar via OAuth
  2. User can authenticate with Outlook/Microsoft 365 via OAuth
  3. Events from external calendars appear in menu bar and dropdown
  4. OAuth tokens are stored securely in Keychain
  5. Token expiry prompts user to re-authenticate
  6. Architecture supports adding other calendar sources
**Plans**: 6 plans

Plans:
- [x] 05-01-PLAN.md — Provider architecture (CalendarProviderType, CalendarProvider protocol, LocalCalendarProvider)
- [x] 05-02-PLAN.md — Auth infrastructure (KeychainService, AuthService with ASWebAuthenticationSession)
- [x] 05-03-PLAN.md — Google Calendar provider (GoogleCalendarProvider, Google API models)
- [x] 05-04-PLAN.md — Outlook Calendar provider (OutlookCalendarProvider, Microsoft Graph models)
- [x] 05-05-PLAN.md — Multi-provider integration (CalendarProviderManager, EventCacheService, AppState update)
- [x] 05-06-PLAN.md — Account management UI (CalendarSettingsView extension, AddAccountSheet)

### Phase 6: Meeting Links + Notifications
**Goal**: One-click meeting join and pre-event reminders
**Depends on**: Phase 5
**Requirements**: ACTN-01, ACTN-02, ACTN-03, ACTN-04, ACTN-05, NOTF-01, NOTF-02, NOTF-03, NOTF-04, NOTF-05, SYST-03, SYST-04
**Success Criteria** (what must be TRUE):
  1. User can join meeting with one click when event has meeting URL
  2. User can get directions for events with location
  3. User can copy event link or details
  4. User sees travel time and leave time for events with locations
  5. User can quick-add event from dropdown
  6. User receives popup reminder 5min before event
  7. Popup stays until dismissed
  8. User can snooze reminder (3min, 5min, 10min options)
  9. User can customize notification sound
  10. User can configure notification preferences
  11. Focus mode filters events by context
  12. User sees warnings for overlapping events
**Plans**: 6 plans

Plans:
- [x] 06-01-PLAN.md — Event model extension + meeting URL parser
- [x] 06-02-PLAN.md — NotificationService with UNUserNotificationCenter
- [x] 06-03-PLAN.md — Event actions (Join, Directions, Copy)
- [x] 06-04-PLAN.md — Travel time + conflict detection
- [x] 06-05-PLAN.md — Notification settings + snooze
- [x] 06-06-PLAN.md — Focus mode + quick-add

### Phase 7: Distribution + Notarization
**Goal**: Code signing, notarization, and public release
**Depends on**: Phase 6
**Requirements**: None (distribution-focused)
**Success Criteria** (what must be TRUE):
  1. App is code-signed with valid Developer ID
  2. App is notarized by Apple
  3. App has proper sandbox entitlements
  4. Homebrew cask is available for installation
  5. GitHub releases have compiled binaries
  6. App passes Gatekeeper on fresh install
**Plans**: 6 plans

Plans:
- [ ] 07-01-PLAN.md — Sparkle auto-update integration
- [ ] 07-02-PLAN.md — Open source community files (LICENSE, CONTRIBUTING, templates)
- [ ] 07-03-PLAN.md — What's New screen + CHANGELOG
- [ ] 07-04-PLAN.md — GitHub Actions release workflow (sign, notarize, DMG)
- [ ] 07-05-PLAN.md — README documentation
- [ ] 07-06-PLAN.md — Homebrew tap creation

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Core Menu Bar + Local Calendar | 3/3 | Complete | 2026-01-24 |
| 2. Live Countdown + Urgency | 3/3 | Complete | 2026-01-24 |
| 3. Dropdown Event List | 3/3 | Complete | 2026-01-24 |
| 4. Polish + Launch Essentials | 3/3 | Complete | 2026-01-24 |
| 5. External Calendar APIs | 6/6 | Complete | 2026-01-24 |
| 6. Meeting Links + Notifications | 6/6 | Complete | 2026-01-25 |
| 7. Distribution + Notarization | 0/6 | Not started | - |
