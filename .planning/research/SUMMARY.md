# Project Research Summary

**Project:** ToEvent
**Domain:** macOS menu bar calendar app with live countdown
**Researched:** 2026-01-24
**Confidence:** HIGH

## Executive Summary

ToEvent is a macOS menu bar app that displays upcoming calendar events with a live countdown timer. Expert research shows this is a well-established category with clear architectural patterns: SwiftUI MenuBarExtra for UI, EventKit for local calendar access, and careful timer management for battery efficiency. The recommended approach is Swift 6.2 with SwiftUI, leveraging macOS 13+ APIs to avoid AppKit complexity while maintaining native feel.

The core differentiator is the live countdown with color-coded urgency (green/yellow/red) — a feature missing from major competitors like MeetingBar and Itsycal. However, this differentiator introduces the highest risk: battery drain from frequent UI updates. Research confirms this can be mitigated through TimelineView, timer tolerance settings, and NSBackgroundActivityScheduler rather than polling.

Critical path dependencies are clear: EventKit integration must work before countdown logic, countdown must work before urgency indicators, and local calendar must be stable before adding Google/Outlook APIs. The primary pitfall is permission handling (EventKit requires specific Info.plist keys and changes in macOS 14+), followed by timer efficiency (must use tolerance settings and TimelineView to avoid battery complaints).

## Key Findings

### Recommended Stack

Swift 6.2 with SwiftUI provides the optimal foundation. The language's modern concurrency (async/await with MainActor isolation) eliminates entire classes of threading bugs common in menu bar apps. SwiftUI's MenuBarExtra scene (macOS 13+) avoids AppKit NSStatusItem boilerplate while maintaining native integration.

**Core technologies:**
- Swift 6.2: Modern concurrency with data-race safety by default, eliminating threading bugs in timer updates
- SwiftUI MenuBarExtra: Native menu bar integration without AppKit bridging (macOS 13+ requirement is acceptable — covers 95%+ of active Macs)
- EventKit: Apple's calendar framework with single EKEventStore pattern and notification-based sync (no polling)
- TimelineView: Battery-efficient time-based updates designed specifically for menu bar apps (solves SwiftUI timer runloop issues)
- UserNotifications: Local notifications for event reminders
- async/await: One-off API calls to Google/Outlook (cleaner than Combine for non-streaming operations)
- Combine: Real-time countdown updates and continuous UI state changes (ideal for timer-based streams)

**Critical versions:**
- macOS 13.0+ minimum (enables MenuBarExtra, covers 95% of users)
- Swift 6.2 required (approachable concurrency, MainActor defaults)
- EventKit write-only access on macOS 14+ (privacy-first design)

**What NOT to use:**
- Electron (200MB+ memory, battery drain, non-native)
- Polling for calendar updates (use EKEventStoreChanged notifications)
- Multiple EKEventStore instances (Apple explicitly warns against this)
- Natural language parsing (Fantastical's complexity, not worth it for v1)

### Expected Features

**Must have (table stakes):**
- Display calendar events from macOS Calendar app — users expect native integration
- Show next/upcoming event in menu bar — core value proposition
- List of upcoming events in dropdown — all competitors provide this
- Calendar color coding — users rely on visual distinction
- All-day event handling — common event type, different display format
- System light/dark mode support — expected from modern macOS apps
- EventKit permission handling — macOS enforces this, no workarounds

**Should have (competitive advantage):**
- Live countdown timer in menu bar — ToEvent's differentiator, constant awareness
- Color-coded urgency warnings — glanceable status (green > yellow > red based on time remaining)
- Minimal menu bar footprint — competitors like Fantastical show too much, users value space
- Join meeting link with one click — MeetingBar's killer feature, reduces friction
- Keyboard shortcut to open dropdown — power users expect this
- Filter which calendars to show — reduce noise for multi-calendar users
- Auto-launch at login — users expect menu bar apps to persist

**Defer (v2+):**
- Week number display — niche, primarily European market
- Time zone display — small audience
- URL scheme for automation — integration feature, can wait
- Custom date/time formats — most users fine with system locale

**Anti-features (commonly requested but problematic):**
- Edit events in-app — duplicates Calendar.app, creates sync conflicts, massive scope
- Natural language parsing — extremely complex, lokalization multiplies difficulty
- Show Google Calendar directly — duplicates EventKit, adds OAuth complexity unnecessarily (users can add Google to Calendar.app)
- Weather integration — marginal value, increases battery drain, requires permissions
- Full calendar grid view — violates minimal footprint principle

### Architecture Approach

The standard architecture is four-layer: Presentation (MenuBarExtra/NSStatusItem + popover), State (@Observable container), Service (CalendarService, TimerManager, NotificationService), and Data (EventKit + external APIs). This separation enables testable business logic, swappable calendar providers, and clean UI updates through SwiftUI observation.

**Major components:**
1. **MenuBarExtra** — Menu bar UI entry point using SwiftUI scene (macOS 13+), handles system integration
2. **AppState** — @Observable central state with currentEvent, upcomingEvents, timeRemaining, urgencyLevel (single source of truth)
3. **CalendarService** — Orchestrates multiple calendar providers (EventKit, Google, Outlook) with provider pattern
4. **TimerManager** — Real-time countdown updates using Timer with 0.5s tolerance for battery efficiency
5. **EventKitProvider** — Local calendar access with singleton EKEventStore, monitors EKEventStoreChanged notifications
6. **NotificationService** — Push reminders before events start

**Key patterns:**
- Service Provider Pattern: Abstract calendar access behind protocol, swap EventKit/Google/Outlook implementations
- Observable State Container: Single @Observable class with automatic UI updates
- Timer with Tolerance: Allow system coalescing (timer.tolerance = 0.5 for 1s intervals) to reduce CPU wake-ups
- Notification-Based Sync: Subscribe to EKEventStoreChanged instead of polling (battery efficient, immediate updates)
- TimelineView: Use instead of .onReceive(timer) to work around SwiftUI/MenuBarExtra runloop issues

### Critical Pitfalls

1. **Battery Drain from Frequent UI Updates** — Countdown timers updating every second drain battery significantly if implemented wrong. Must use timer tolerance (0.5s for 1s intervals), TimelineView for UI updates, and stop timers when menu closed. Warning signs: Activity Monitor showing >5% CPU idle, "High" energy impact. Prevention phase: Phase 1 (timer must be efficient from start).

2. **EventKit Permission Handling Failures** — Permission requests fail silently or crash app. macOS 14+ changed API, now requires NSCalendarsFullAccessUsageDescription key. Must use single shared EKEventStore instance, request on first use (not at launch), check authorization before every operation. Warning signs: permission dialog never appears, crashes with "privacy violation" errors. Prevention phase: Phase 1 (must work before any calendar features).

3. **EventKit Database Change Notifications Ignored** — Events become stale when modified in Calendar.app or iOS devices. Must subscribe to EKEventStoreChanged notification immediately after creating store, invalidate cached events when fired. Warning signs: events don't match Calendar.app, deleted events still showing. Prevention phase: Phase 1 (database sync critical from first release).

4. **SwiftUI Timer Not Working in MenuBarExtra** — Timers using .onReceive(timer) don't fire inside MenuBarExtra with .menu style due to runloop blocking. Must use TimelineView instead (designed for menu bar updates), or dedicated ObservableObject with timer initialized there. Warning signs: timer works in preview but fails in menu bar, countdown freezes. Prevention phase: Phase 1 (must validate timer approach before building features).

5. **OAuth Token Refresh Limits Exceeded** — Google Calendar API stops working because refresh tokens invalidated. Google enforces limits per client-user, and March 2025 requires OAuth (no more basic auth). Must store refresh token in Keychain, reuse until revoked, never request new token if valid one exists. Warning signs: authentication stopped working after app was functional, 401/403 errors. Prevention phase: Phase 3 (before implementing external calendar APIs).

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Core Menu Bar + Local Calendar
**Rationale:** MenuBarExtra and EventKit are foundational. All features depend on these working correctly. EventKit permission handling, timer efficiency, and database sync must be validated before building anything else.

**Delivers:** Menu bar presence with next event display, basic EventKit integration, permission handling

**Addresses:**
- Display calendar events from macOS Calendar (table stakes)
- Show next event in menu bar (core value)
- EventKit permission handling (required)
- Respect calendar permissions (required)

**Avoids:**
- Menu bar space limitations (detect nil, provide fallback)
- EventKit permission failures (Info.plist keys, request on first use)
- NSStatusItem memory issues (store strong reference)

**Research flag:** Standard patterns, skip research-phase. MenuBarExtra and EventKit are well-documented.

### Phase 2: Live Countdown + Urgency
**Rationale:** Countdown timer is the core differentiator but requires working EventKit first. This phase validates battery efficiency before adding complexity. Must use TimelineView to avoid SwiftUI/MenuBarExtra runloop issues.

**Delivers:** Real-time countdown in menu bar, color-coded urgency indicators (green/yellow/red)

**Addresses:**
- Live countdown timer (differentiator)
- Color-coded urgency warnings (competitive advantage)
- Minimal menu bar footprint (competitive advantage)

**Avoids:**
- Battery drain from frequent updates (timer tolerance, TimelineView)
- SwiftUI timer failures in MenuBarExtra (use TimelineView not .onReceive)
- No timer tolerance (set 0.5s tolerance for 1s intervals)

**Implements:** TimerManager, UrgencyLevel model, TimelineView-based updates

**Research flag:** Standard patterns, skip research-phase. Timer tolerance and TimelineView are documented.

### Phase 3: Dropdown Event List
**Rationale:** With menu bar working and countdown validated, add full event list UI. This completes the table stakes feature set. Popover vs NSMenu decision point.

**Delivers:** Clickable dropdown with upcoming events, event details (time, title, calendar color), scrollable list

**Addresses:**
- List of upcoming events in dropdown (table stakes)
- Click to expand dropdown (table stakes)
- Event time/title/color display (table stakes)
- All-day event handling (table stakes)
- Light/dark mode support (table stakes)

**Avoids:**
- NSPopover issues (consider NSMenu for simpler UI, NSPanel for complex)

**Implements:** PopoverView/NSMenu, EventRow component

**Research flag:** Standard patterns, skip research-phase. Popover/menu implementation is well-documented.

### Phase 4: Polish + Launch Essentials
**Rationale:** Features users notice missing quickly after initial use. Auto-launch, keyboard shortcut, and calendar filtering are high-value, low-complexity additions that complete v1.

**Delivers:** Auto-launch at login, global keyboard shortcut, calendar filtering preferences, settings UI

**Addresses:**
- Keyboard shortcut to open (power user expectation)
- Filter which calendars appear (reduces noise)
- Auto-launch at login (users expect persistence)

**Avoids:**
- Auto-launch conflicts with sandboxing (use ServiceManagement modern API)

**Research flag:** Standard patterns, skip research-phase. LaunchAtLogin and hotkey registration are well-documented.

### Phase 5: External Calendar APIs
**Rationale:** Defer until local calendar is stable. Google/Outlook APIs add OAuth complexity, token management, and rate limiting concerns. Provider pattern architecture enables clean integration.

**Delivers:** Google Calendar integration, Outlook/Microsoft 365 integration, OAuth flows, token storage

**Addresses:**
- Google Calendar API access (optional feature)
- Microsoft Graph Calendar access (optional feature)

**Uses:**
- GoogleSignIn SDK + GoogleAPIClient
- Microsoft Graph SDK
- Provider pattern (abstract behind CalendarProvider protocol)

**Avoids:**
- OAuth token refresh limits (store in Keychain, reuse tokens)
- Background polling inefficiency (use NSBackgroundActivityScheduler)

**Implements:** GoogleCalendarProvider, OutlookCalendarProvider, OAuth flow UI, Keychain token storage

**Research flag:** Needs research-phase. OAuth flows, token management, and API rate limits require domain-specific investigation.

### Phase 6: Meeting Links + Notifications
**Rationale:** High-value features but not required for core functionality. Meeting link detection has known patterns (MeetingBar open source), notifications use standard UserNotifications framework.

**Delivers:** Parse meeting URLs from event notes/location, one-click join button, pre-event notifications, notification preferences

**Addresses:**
- Join meeting link with one click (competitive feature)
- Notification before event starts (valuable feature)

**Avoids:**
- Complex meeting service detection (use MeetingBar's regex patterns)

**Research flag:** Needs research-phase for meeting URL patterns (50+ services), standard for notifications.

### Phase 7: Distribution + Notarization
**Rationale:** Final phase before public release. App Store requires sandboxing entitlements, Homebrew requires notarization. Both have specific gotchas that must be addressed.

**Delivers:** Code signing, notarization, sandbox entitlements, Homebrew cask, App Store submission

**Avoids:**
- Sandboxing violations (add calendar, network entitlements)
- Notarization failures (use notarytool not altool)
- Homebrew cask issues (auto_updates stanza, notarized DMG)

**Research flag:** Standard patterns, skip research-phase. Code signing and notarization are well-documented (though tedious).

### Phase Ordering Rationale

- **Dependencies drive order:** EventKit must work before countdown, countdown before urgency, local before external APIs
- **Validate differentiator early:** Phase 2 validates battery-efficient countdown (highest risk) before building more features
- **Defer complexity:** External APIs (Phase 5) and meeting links (Phase 6) deferred until core is stable
- **Progressive enhancement:** Each phase adds visible value, app is shippable after Phase 4
- **Architecture validates patterns:** Provider pattern proven in Phase 1-3 before applying to external APIs in Phase 5

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 5 (External Calendar APIs):** OAuth flows are well-documented but token refresh limits, rate limiting strategies, and API-specific quirks require investigation per provider
- **Phase 6 (Meeting Links):** 50+ meeting services with different URL patterns, need to research MeetingBar's detection logic and update for 2026

Phases with standard patterns (skip research-phase):
- **Phase 1 (Core Menu Bar):** MenuBarExtra and EventKit extensively documented by Apple
- **Phase 2 (Countdown Timer):** TimelineView and timer tolerance have clear examples
- **Phase 3 (Dropdown UI):** NSPopover/NSMenu patterns well-established
- **Phase 4 (Polish):** LaunchAtLogin and keyboard shortcuts are solved problems
- **Phase 7 (Distribution):** Code signing/notarization tedious but documented

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Swift 6.2, SwiftUI MenuBarExtra, EventKit all official Apple frameworks with extensive documentation. Version requirements validated against macOS release dates. |
| Features | HIGH | Competitor analysis of 5+ menu bar calendar apps (MeetingBar, Itsycal, Dato, Calendr, Fantastical). Table stakes clearly identified, anti-features have documented rationales. |
| Architecture | HIGH | Multiple sources confirm service provider pattern, observable state, timer tolerance, notification-based sync. Architecture research cites recent (2025) sources on MenuBarExtra communication patterns. |
| Pitfalls | MEDIUM-HIGH | Battery drain, EventKit permissions, timer issues all documented with official Apple sources. OAuth token limits confirmed in Google docs. Lower confidence on edge cases (menu bar space overflow recovery). |

**Overall confidence:** HIGH

Research is comprehensive with primary sources (Apple documentation, official API docs) for all critical paths. Competitor analysis validates feature priorities. Architecture patterns confirmed across multiple recent tutorials and blog posts.

### Gaps to Address

- **Menu bar space overflow recovery:** Research identifies the problem (statusItem can return nil when menu bar full) but recovery strategies are speculative. Should test extensively with 15+ menu bar items during Phase 1 to validate fallback UI.

- **TimelineView performance at scale:** Research confirms TimelineView solves SwiftUI/MenuBarExtra timer issues, but no source validates performance with 100+ events visible. May need to implement virtual scrolling if performance degrades.

- **OAuth token refresh edge cases:** Google's token refresh limits are documented but exact thresholds unclear. Should implement telemetry (privacy-respecting) during Phase 5 to detect token invalidation patterns.

- **Meeting URL pattern coverage:** MeetingBar supports 50+ services but research doesn't verify completeness for 2026. During Phase 6, audit pattern list against current meeting service landscape (Zoom, Teams, Meet, Webex, etc.).

- **Sandboxing compatibility with global hotkeys:** Research mentions potential conflicts but doesn't confirm CGEventTap works in sandboxed apps. Test during Phase 4 keyboard shortcut implementation, have fallback plan (Shortcuts.app integration) if blocked.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: EventKit, MenuBarExtra, Energy Efficiency Guide, Notarization
- Swift.org: Swift 6.2 release notes, approachable concurrency guide
- Google Calendar API: OAuth errors, rate limits, transition to OAuth
- Microsoft Graph: Outlook Calendar API overview
- Competitor apps: MeetingBar (GitHub), Itsycal, Dato, Calendr, Fantastical feature pages

### Secondary (MEDIUM confidence)
- sarunw.com: SwiftUI menu bar app tutorial (2023)
- TrozWare: Mac menubar and SwiftUI communication (2025)
- nemecek.be: EventKit change monitoring
- Multiple Medium/dev.to posts on menu bar app development (2023-2025)

### Tertiary (LOW confidence, needs validation)
- Menu bar space limits: No official Apple documentation on overflow behavior, inferred from developer forum discussions
- Timer tolerance impact: Apple recommends setting tolerance but doesn't quantify battery savings, inferred from general energy efficiency principles

---
*Research completed: 2026-01-24*
*Ready for roadmap: yes*
