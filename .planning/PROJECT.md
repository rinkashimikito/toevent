# ToEvent (working name)

## What This Is

A macOS menu bar app that displays your next calendar event with a live countdown, color-coded urgency warnings, and a dropdown list of upcoming events. Built for people who need constant visibility of what's coming next without switching to Calendar.app. Open source, distributed via GitHub and Homebrew.

## Core Value

Constant visibility of the next event with time remaining. If everything else fails, the menu bar must show the next event and countdown.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Display next event in menu bar with countdown timer
- [ ] Color-code menu bar text based on time remaining (1h yellow, 30m orange, 15m red)
- [ ] Show popup reminder at 5min before event (stays until dismissed)
- [ ] Dropdown list of upcoming events (chronological, with countdowns)
- [ ] Integrate with macOS calendars (EventKit)
- [ ] Allow opt-out of specific calendars
- [ ] Settings panel accessible from dropdown (bottom, cog icon)
- [ ] Event details on click
- [ ] Color customization for calendars and event types
- [ ] Google Calendar integration
- [ ] Outlook Calendar integration
- [ ] Support for other calendar sources
- [ ] Configurable number of events shown in dropdown
- [ ] Events disappear from list after they start
- [ ] Fixed-size dropdown with scrollable list
- [ ] Travel time awareness (calculate leave time using Maps for events with locations)
- [ ] Quick actions on events (Join Meeting, Get Directions, Copy Link)
- [ ] Snooze option on popup reminder (3min, 5min, 10min)
- [ ] Global keyboard shortcut to show/hide dropdown
- [ ] Time display options (countdown vs absolute time vs both)
- [ ] Custom time thresholds for color changes (user-configurable intervals)
- [ ] All-day event handling (display as "Today" instead of countdown)
- [ ] Privacy mode (hide event titles when sharing screen)
- [ ] Natural language in menu bar ("Laundry soon" vs "in 5min")
- [ ] Focus mode integration (filter events by context)
- [ ] Conflict warnings for overlapping events
- [ ] Quick-add event from dropdown
- [ ] Menu bar icon states (icon changes based on urgency)
- [ ] Sound alerts for popup (customizable sound)
- [ ] Real-time countdown updates (UI refreshes every second)
- [ ] Configurable calendar fetch interval (poll for new events every X minutes)
- [ ] Battery optimization for background polling

### Out of Scope

- iOS/iPadOS versions — macOS only for v1
- Windows/Linux support — macOS-native only
- Paid features or subscriptions — free and open source
- Calendar editing beyond quick-add — read-focused with minimal write

## Context

**Target platform:** macOS (latest version) using native frameworks (SwiftUI + EventKit)

**Distribution:** Open source on GitHub with compiled releases + Homebrew cask for easy installation

**Name:** "ToEvent" is working name - need catchy final name before public release

**Technical approach:**
- Native macOS app (not Electron) for performance and battery efficiency
- EventKit for macOS calendar access
- External calendar APIs (Google Calendar API, Microsoft Graph API) for third-party integrations
- Background refresh with battery-aware polling

**User experience priorities:**
- Minimal clicks to see what's next
- Non-intrusive but impossible to miss urgent events
- Customizable to match different workflows (privacy mode, focus integration, time formats)

## Constraints

- **Platform**: macOS only (latest version) — Native app using Swift/SwiftUI
- **Distribution**: Free only (GitHub + Homebrew) — No paid tiers or App Store initially
- **Privacy**: Local-first where possible — Calendar data stays on device, third-party APIs use OAuth
- **Performance**: Minimal battery impact — Smart polling, efficient background refresh
- **Access**: Requires Calendar permissions — EventKit needs user authorization

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Native macOS (Swift) over Electron | Better performance, battery life, integration with system APIs | — Pending |
| Open source from day one | Community contributions, trust, transparency | — Pending |
| Include all features in v1 | User requested comprehensive feature set upfront | — Pending |

---
*Last updated: 2026-01-24 after initialization*
