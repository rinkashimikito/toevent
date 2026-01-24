# Requirements: ToEvent

**Defined:** 2026-01-24
**Core Value:** Constant visibility of next event with time remaining

## v1 Requirements

### Calendar Integration

- [x] **CALD-01**: Display events from macOS Calendar app (EventKit)
- [x] **CALD-02**: Request and handle calendar permissions
- [x] **CALD-03**: Opt-out specific calendars from display
- [x] **CALD-04**: Google Calendar OAuth integration
- [x] **CALD-05**: Outlook/Microsoft 365 Calendar OAuth integration
- [x] **CALD-06**: Support for other calendar sources (extensible architecture)
- [x] **CALD-07**: Real-time event sync with configurable fetch interval
- [x] **CALD-08**: Show calendar color coding for events
- [x] **CALD-09**: Handle all-day events appropriately

### Menu Bar Display

- [x] **MENU-01**: Display next event title in menu bar
- [x] **MENU-02**: Show live countdown timer (updates every second)
- [x] **MENU-03**: Color-code menu bar text by urgency (1h yellow, 30m orange, 15m red)
- [x] **MENU-04**: Change menu bar icon based on urgency level
- [x] **MENU-05**: Support light and dark mode
- [x] **MENU-06**: Natural language option ("soon" vs "in 5min")
- [x] **MENU-07**: Privacy mode to hide event titles

### Dropdown Event List

- [x] **DROP-01**: Click menu bar to expand dropdown
- [x] **DROP-02**: Show configurable number of upcoming events
- [x] **DROP-03**: Display event time and countdown for each event
- [x] **DROP-04**: Fixed-size dropdown with scrollable list
- [x] **DROP-05**: Click event to show full details
- [x] **DROP-06**: Settings panel at bottom with cog icon
- [x] **DROP-07**: Events disappear after they start

### Notifications & Reminders

- [x] **NOTF-01**: Show popup reminder at 5min before event
- [x] **NOTF-02**: Popup stays until user dismisses
- [x] **NOTF-03**: Snooze options (3min, 5min, 10min)
- [x] **NOTF-04**: Customizable sound alerts
- [x] **NOTF-05**: Notification preferences in settings

### Event Actions

- [x] **ACTN-01**: Quick Join Meeting button (detect meeting URLs)
- [x] **ACTN-02**: Get Directions button (for events with location)
- [x] **ACTN-03**: Copy event link/details
- [x] **ACTN-04**: Travel time awareness (calculate leave time with Maps)
- [x] **ACTN-05**: Quick-add event from dropdown

### Customization

- [ ] **CUST-01**: Customize colors for calendars
- [ ] **CUST-02**: Customize colors for event types
- [x] **CUST-03**: Configure time thresholds for color warnings
- [x] **CUST-04**: Choose time display format (countdown/absolute/both)
- [x] **CUST-05**: Set calendar fetch interval
- [x] **CUST-06**: Configure number of events to display

### System Integration

- [x] **SYST-01**: Global keyboard shortcut to toggle dropdown
- [x] **SYST-02**: Auto-launch at login
- [x] **SYST-03**: Focus mode integration (filter by context)
- [x] **SYST-04**: Conflict warnings for overlapping events
- [x] **SYST-05**: Battery optimization for background tasks

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced Features

- **ADV-01**: Week number display in dropdown
- **ADV-02**: Time zone display for events
- **ADV-03**: URL scheme for automation
- **ADV-04**: Keyboard navigation in dropdown
- **ADV-05**: Custom date/time format strings

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| iOS/iPadOS versions | macOS-only for v1, different UX paradigm |
| Windows/Linux support | Native macOS app using Swift/SwiftUI |
| Paid features or subscriptions | Free and open source distribution model |
| Full event editing | Duplicates Calendar.app, creates sync conflicts |
| Natural language event parsing | Extremely complex, localization multiplies difficulty |
| Direct calendar API integration (without EventKit) | Duplicates what EventKit provides, unnecessary complexity |
| Weather integration | Marginal value, requires permissions, drains battery |
| Full calendar grid view | Violates minimal footprint principle |
| Task management / reminders | Different UX needs, scope creep |
| Analytics / usage tracking | Privacy-first approach, conflicts with open source ethos |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CALD-01 | Phase 1 | Complete |
| CALD-02 | Phase 1 | Complete |
| CALD-03 | Phase 1 | Complete |
| CALD-07 | Phase 1 | Complete |
| CALD-09 | Phase 1 | Complete |
| MENU-01 | Phase 1 | Complete |
| MENU-05 | Phase 1 | Complete |
| MENU-02 | Phase 2 | Complete |
| MENU-03 | Phase 2 | Complete |
| MENU-04 | Phase 2 | Complete |
| CALD-08 | Phase 2 | Complete |
| DROP-01 | Phase 3 | Complete |
| DROP-02 | Phase 3 | Complete |
| DROP-03 | Phase 3 | Complete |
| DROP-04 | Phase 3 | Complete |
| DROP-05 | Phase 3 | Complete |
| DROP-06 | Phase 3 | Complete |
| DROP-07 | Phase 3 | Complete |
| SYST-01 | Phase 4 | Complete |
| SYST-02 | Phase 4 | Complete |
| CUST-03 | Phase 4 | Complete |
| CUST-04 | Phase 4 | Complete |
| CUST-05 | Phase 4 | Complete |
| CUST-06 | Phase 4 | Complete |
| MENU-06 | Phase 4 | Complete |
| MENU-07 | Phase 4 | Complete |
| SYST-05 | Phase 4 | Complete |
| CALD-04 | Phase 5 | Complete |
| CALD-05 | Phase 5 | Complete |
| CALD-06 | Phase 5 | Complete |
| ACTN-01 | Phase 6 | Complete |
| ACTN-02 | Phase 6 | Complete |
| ACTN-03 | Phase 6 | Complete |
| ACTN-04 | Phase 6 | Complete |
| ACTN-05 | Phase 6 | Complete |
| NOTF-01 | Phase 6 | Complete |
| NOTF-02 | Phase 6 | Complete |
| NOTF-03 | Phase 6 | Complete |
| NOTF-04 | Phase 6 | Complete |
| NOTF-05 | Phase 6 | Complete |
| SYST-03 | Phase 6 | Complete |
| SYST-04 | Phase 6 | Complete |

**Coverage:**
- v1 requirements: 44 total
- Mapped to phases: 44
- Unmapped: 0

---
*Requirements defined: 2026-01-24*
*Last updated: 2026-01-24 after roadmap creation*
