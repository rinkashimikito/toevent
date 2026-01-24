# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-24)

**Core value:** Constant visibility of the next event with time remaining. If everything else fails, the menu bar must show the next event and countdown.
**Current focus:** Phase 7 - Distribution + Notarization

## Current Position

Phase: 7 of 7 (Distribution + Notarization)
Plan: 6 of 6 in current phase
Status: In progress (awaiting verification checkpoint)
Last activity: 2026-01-26 - Completed 07-06-PLAN.md Tasks 1-2

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**
- Total plans completed: 29
- Average duration: 3m
- Total execution time: 1.78 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 15m | 5m |
| 02 | 3 | 15m | 5m |
| 03 | 3 | 12m | 4m |
| 04 | 3 | 12m | 4m |
| 05 | 6 | 14m | 2m |
| 06 | 6 | 20m | 3m |
| 07 | 5 | 13m | 2.6m |

**Recent Trend:**
- Last 5 plans: 07-01 (3m), 07-03 (3m), 07-05 (1m), 07-06 (3m)
- Trend: Stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Init: Native macOS (Swift) over Electron for better performance and battery life
- Init: Open source from day one for community contributions and trust
- Init: Include all features in v1 as requested
- 01-01: MenuBarExtra uses .window style (not .menu) for timer compatibility
- 01-01: macOS 13.0 minimum deployment target for MenuBarExtra support
- 01-02: ObservableObject over @Observable for macOS 13 compatibility
- 01-02: IntroView inside MenuBarExtra window (simpler than separate Window scene)
- 01-03: MenuBarLabel as separate view with @ObservedObject for proper state observation
- 01-03: @unchecked Sendable for CalendarService (singleton with controlled access)
- 01-03: sindresorhus/Settings typealiases to avoid SwiftUI.Settings ambiguity
- 02-01: Urgency thresholds at 15m/30m/60m for imminent/soon/approaching
- 02-01: Show seconds when under 5 minutes for hybrid countdown format
- 02-01: Treat system wake as potential unlock for edge case handling
- 02-03: Flat reorderable list for calendar priority (source shown as secondary label)
- 02-03: Store calendar IDs in priority order array (survives renames)
- 02-02: Timer-based updates instead of TimelineView (MenuBarExtra label compatibility)
- 03-01: nextEvent derived from events.first (single source of truth)
- 03-01: Event expiry refresh when startDate <= currentTime
- 03-02: VStack over List for event rows (better menu bar popup styling)
- 03-02: Removed Quit button from footer (Cmd+Q exists, cleaner UI)
- 03-02: Calendar color tint at 0.1 opacity on hover
- 03-03: AppleScript via NSAppleScript (only reliable method to open specific events)
- 03-03: Error logging without user alert for AppleScript failures
- 04-02: TimeDisplayFormat enum for format selection (countdown/absolute/both)
- 04-02: Natural language thresholds at fixed intervals (soon, shortly, in under an hour)
- 04-02: Privacy mode at display layer only (titles masked in UI)
- 04-01: ShortcutHandler ObservableObject for keyboard shortcut binding (MenuBarExtra @State limitation)
- 04-03: UrgencyThresholds struct with imminent/soon/approaching values
- 04-03: NSBackgroundActivityScheduler with 25% tolerance for battery optimization
- 04-03: Stepper controls with validation for threshold ordering
- 05-01: CalendarProvider protocol for multi-source abstraction
- 05-01: LocalCalendarProvider delegates to CalendarService (no duplication)
- 05-01: macOS 13/14 compatible authorization check (#available for fullAccess)
- 05-01: Event.source and CalendarInfo.providerType for source tracking
- 05-02: Native Security framework over Valet (simpler, no external dependency)
- 05-02: Placeholder client IDs in source (user configures own OAuth credentials)
- 05-02: network.client entitlement for OAuth token exchange
- 05-03: ISO8601DateFormatter with fractional seconds fallback for Google date parsing
- 05-03: Skip calendar on fetch error, continue with others (resilient fetching)
- 05-03: URL path encoding for calendar IDs containing special characters
- 05-04: Windows timezone name mapping for Microsoft Graph dates
- 05-04: Microsoft color names to CGColor conversion
- 05-04: URL-encode calendar IDs in Microsoft Graph paths
- 05-05: CodableEvent wrapper for JSON serialization (CGColor not Codable)
- 05-05: CGColor hex string encoding for cache persistence
- 05-05: any CalendarProvider array type for heterogeneous provider storage
- 05-05: Cache fallback on both auth and network errors
- 05-06: AddAccountSheet uses callback pattern for account creation notification
- 05-06: Provider symbol icons indicate calendar source in list
- 05-06: Re-auth warning section appears at top when accounts expire
- 05-06: SettingsContainer/SettingsSection for consistent settings UI
- 06-01: Explicit URL > location > notes for meeting URL detection priority
- 06-01: hangoutLink/onlineMeeting.joinUrl takes priority over text parsing
- 06-01: URLs stored as strings in CodableEvent for JSON serialization
- 06-02: NotificationSoundOption enum with default/subtle/urgent/none
- 06-02: Snooze actions 3/5/10 min via UNNotificationCategory
- 06-02: Join meeting action opens URL via NSWorkspace
- 06-03: maps:// URL scheme for Apple Maps directions
- 06-03: AppleScript for opening local events in Calendar app
- 06-03: Hover reveals Join button when meeting URL exists, ellipsis for detail popover
- 06-04: In-memory dictionary cache for travel time by address
- 06-04: 5-minute buffer added to travel time for leave time calculation
- 06-04: Exclude all-day events from conflict detection
- 06-05: Separate NotificationSoundOption enum in AppState with conversion to service type
- 06-05: Default reminder time 5 minutes if not set
- 06-05: Alert style guidance section in NotificationSettingsView
- 06-06: Focus filter state stored in UserDefaults with notification
- 06-06: Dynamic DisplayRepresentation for Focus UI status
- 06-06: AppleScript opens Calendar.app for quick-add event creation
- 07-01: SPUStandardUpdaterController for standard update UI
- 07-01: SUFeedURL to releases/latest/download for release artifacts
- 07-01: Empty SUPublicEDKey (EdDSA key generated during first release)
- 07-03: Skip What's New on first launch (no previous version to compare)
- 07-03: Hardcode changelog content in WhatsNewView (simpler than parsing)
- 07-05: xattr -cr instructions for Homebrew and direct download (unsigned app)
- 07-05: Explain Gatekeeper behavior for unsigned distribution
- 07-06: sha256 :no_check for initial release (update after first actual release)
- 07-06: postflight xattr -cr for unsigned app Gatekeeper bypass
- 07-06: Caveats block explains manual xattr workaround

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-01-26
Stopped at: Completed 07-06-PLAN.md Tasks 1-2, awaiting verification
Resume file: None
