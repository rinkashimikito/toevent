# Phase 1: Core Menu Bar + Local Calendar - Research

**Researched:** 2026-01-24
**Domain:** SwiftUI MenuBarExtra + EventKit integration
**Confidence:** HIGH

## Summary

Phase 1 establishes the menu bar presence and local calendar integration. The core technologies are well-documented and stable: SwiftUI MenuBarExtra (macOS 13+) for UI, EventKit for calendar data, and EKEventStoreChangedNotification for real-time sync.

Key implementation decisions from CONTEXT.md constrain the research scope:
- Menu bar displays "event title + relative time" (e.g., "Standup in 45m")
- Colored dot before title indicating calendar color
- All calendars enabled by default (opt-out model)
- Settings in separate preferences window
- Permission request after intro screen, not at launch

**Primary recommendation:** Use MenuBarExtra with `.window` style to avoid timer issues, TimelineView for periodic updates, singleton EKEventStore, and the sindresorhus/Settings package for preferences window.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI MenuBarExtra | macOS 13+ | Menu bar UI scene | Native SwiftUI, eliminates AppKit bridging |
| EventKit | Framework | Calendar data access | Apple's native calendar API, single source of truth |
| EKEventStore | Singleton | Calendar database connection | Expensive to initialize, Apple recommends one instance |
| TimelineView | SwiftUI | Periodic UI updates | Battery-efficient, avoids runloop timer issues |
| @Observable | macOS 14+ | State management | Modern observation, automatic UI updates |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| DateComponentsFormatter | Foundation | Relative time display | "in 45m" format for countdown |
| UserDefaults | Foundation | Calendar preferences | Store selected calendar IDs |
| sindresorhus/Settings | 3.1+ | Preferences window | Robust Settings scene handling for menu bar apps |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| TimelineView | Timer.publish + onReceive | Timer.publish fails in MenuBarExtra with .menu style |
| sindresorhus/Settings | Native Settings scene | Settings scene has known issues from MenuBarExtra (see Pitfalls) |
| @Observable | @StateObject | @StateObject required if targeting macOS 13 |
| .window style | .menu style | .menu style blocks SwiftUI runloop, breaks timers |

**Installation:**
```bash
# Add via Xcode: File > Add Package Dependencies
# URL: https://github.com/sindresorhus/Settings
```

## Architecture Patterns

### Recommended Project Structure
```
ToEvent/
├── App/
│   ├── ToEventApp.swift           # MenuBarExtra scene, Settings scene
│   └── AppDelegate.swift          # Optional: system events
├── Views/
│   ├── MenuBarView.swift          # Status item content (title + time)
│   ├── IntroView.swift            # Permission request intro screen
│   └── Settings/
│       └── CalendarSettingsView.swift  # Calendar selection toggles
├── State/
│   └── AppState.swift             # @Observable central state
├── Services/
│   └── CalendarService.swift      # EventKit wrapper, singleton store
├── Models/
│   ├── Event.swift                # Unified event model
│   └── CalendarInfo.swift         # Calendar metadata for settings
└── Utilities/
    └── DateFormatters.swift       # Relative time formatting
```

### Pattern 1: Singleton EKEventStore

**What:** Single shared EKEventStore instance for entire app lifetime

**When to use:** Always - EventKit mandates this pattern

**Example:**
```swift
// Source: Apple EventKit documentation
final class CalendarService {
    static let shared = CalendarService()

    private let store = EKEventStore()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeChanges()
    }

    private func observeChanges() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.reloadEvents()
                }
            }
            .store(in: &cancellables)
    }
}
```

### Pattern 2: MenuBarExtra with Window Style

**What:** Use `.menuBarExtraStyle(.window)` instead of default `.menu`

**When to use:** When you need timers, periodic updates, or rich UI

**Example:**
```swift
// Source: Nil Coalescing blog
@main
struct ToEventApp: App {
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .frame(width: 280, height: 60)
        } label: {
            Label("ToEvent", systemImage: "calendar")
        }
        .menuBarExtraStyle(.window)

        Settings {
            CalendarSettingsView()
        }
    }
}
```

### Pattern 3: TimelineView for Periodic Updates

**What:** Use TimelineView with periodic schedule for countdown updates

**When to use:** Real-time display that updates on a schedule (every minute for Phase 1)

**Example:**
```swift
// Source: Apple TimelineView documentation
struct MenuBarView: View {
    @Environment(AppState.self) var appState

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            if let event = appState.nextEvent {
                HStack {
                    Circle()
                        .fill(Color(cgColor: event.calendarColor))
                        .frame(width: 8, height: 8)
                    Text(formatDisplay(event: event, now: context.date))
                        .lineLimit(1)
                }
            } else {
                Text("All clear")
            }
        }
    }
}
```

### Pattern 4: Permission Request with Intro Screen

**What:** Show value proposition before requesting calendar permission

**When to use:** First launch, permission not yet determined

**Example:**
```swift
// Source: CONTEXT.md decision
struct IntroView: View {
    @Environment(\.dismiss) var dismiss
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Never miss a meeting")
                .font(.headline)
            Text("ToEvent shows your next calendar event in the menu bar so you always know what's coming up.")
                .multilineTextAlignment(.center)

            Button("Get Started") {
                Task {
                    isRequesting = true
                    await requestCalendarAccess()
                    dismiss()
                }
            }
            .disabled(isRequesting)
        }
        .padding()
        .frame(width: 300)
    }
}
```

### Anti-Patterns to Avoid

- **Multiple EKEventStore instances:** Creates performance issues, Apple explicitly warns against this
- **Timer.publish in MenuBarExtra:** Fails with .menu style due to runloop blocking
- **Polling instead of EKEventStoreChangedNotification:** Battery drain, unnecessary CPU usage
- **Requesting permission at launch:** Lower grant rate, worse UX
- **Hard-coding calendar filtering:** Store user preferences in UserDefaults

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Calendar data access | Direct database queries | EventKit framework | Privacy, sandboxing, sync with Calendar.app |
| Relative time formatting | Manual string building | DateComponentsFormatter | Localization, pluralization, edge cases |
| Preferences window | Custom window management | sindresorhus/Settings | Scene ordering bugs, activation policy issues |
| Calendar selection UI | Custom list view | EKCalendarChooser or simple toggles | System consistency, accessibility |
| Permission deep-link | URL schemes | Privacy.prefPane (System Settings) | Correct destination, future-proof |

**Key insight:** EventKit handles all calendar complexity including iCloud sync, shared calendars, and timezone handling. Never bypass it.

## Common Pitfalls

### Pitfall 1: Timer Not Firing in MenuBarExtra

**What goes wrong:** Timer.publish with .onReceive stops firing inside MenuBarExtra

**Why it happens:** MenuBarExtra with .menu style blocks SwiftUI's runloop during menu rendering

**How to avoid:**
- Use `.menuBarExtraStyle(.window)` instead of default .menu
- Use TimelineView for periodic updates
- Or use dedicated ObservableObject with Timer initialized outside MenuBarExtra

**Warning signs:** Timer works in preview but freezes in actual menu bar

### Pitfall 2: Settings Window Won't Open

**What goes wrong:** SettingsLink or openSettings does nothing from MenuBarExtra

**Why it happens:** openSettings requires existing SwiftUI render tree, menu bar apps lack standard window context

**How to avoid:**
- Use sindresorhus/Settings package (handles edge cases)
- If using native Settings scene, declare hidden window BEFORE Settings scene
- Toggle activation policy between .accessory and .regular when opening settings

**Warning signs:** Button tap has no effect, no error in console

### Pitfall 3: EventKit Permission Prompt Never Appears

**What goes wrong:** requestFullAccessToEvents returns without showing dialog

**Why it happens:** Missing Info.plist keys, or permission already determined

**How to avoid:**
- Add NSCalendarsFullAccessUsageDescription to Info.plist
- For macOS 13 compatibility, also add NSCalendarsUsageDescription
- Check authorizationStatus before requesting
- Test on clean install (delete app container)

**Warning signs:** .notDetermined status persists after request

### Pitfall 4: Stale Events After External Changes

**What goes wrong:** Events don't update when user modifies calendar in Calendar.app

**Why it happens:** Not subscribing to EKEventStoreChangedNotification

**How to avoid:**
- Subscribe to notification immediately after creating EKEventStore
- When notification fires, invalidate all cached EKEvent instances
- Re-fetch events using fresh predicate
- Do NOT try to diff - notification has no change details

**Warning signs:** App shows deleted events, misses new events

### Pitfall 5: All-Day Events Show Wrong Time

**What goes wrong:** All-day events show countdown to midnight or 00:00

**Why it happens:** isAllDay events have startDate at midnight local time

**How to avoid:**
- Check event.isAllDay before formatting time
- Display "Today" or "Tomorrow" for all-day events (per CONTEXT.md)
- Never show countdown for all-day events

**Warning signs:** "Meeting in 1439m" for an all-day event

### Pitfall 6: App Appears in Dock

**What goes wrong:** Menu bar-only app shows dock icon

**Why it happens:** Missing LSUIElement in Info.plist

**How to avoid:**
- Set LSUIElement = YES in Info.plist (Application is agent)
- Include Quit button in app UI (no dock = no dock quit)
- Handle Cmd+Q via keyboard shortcut in app

**Warning signs:** Dock icon visible, app shows in app switcher

## Code Examples

### EventKit Permission Request (macOS 14+)

```swift
// Source: Apple EventKit documentation
func requestCalendarAccess() async -> Bool {
    let store = CalendarService.shared.store

    switch EKEventStore.authorizationStatus(for: .event) {
    case .fullAccess:
        return true
    case .notDetermined:
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    case .denied, .restricted, .writeOnly:
        return false
    @unknown default:
        return false
    }
}
```

### EventKit Permission Request (macOS 13 compatibility)

```swift
// Source: Apple backwards compatibility guide
func requestCalendarAccessLegacy() async -> Bool {
    let store = CalendarService.shared.store

    if #available(macOS 14.0, *) {
        return try? await store.requestFullAccessToEvents() ?? false
    } else {
        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}
```

### Fetching Events with Calendar Filter

```swift
// Source: EventKit best practices
func fetchUpcomingEvents(
    from calendars: [EKCalendar]?,
    lookahead: TimeInterval = 86400 // 24 hours
) -> [EKEvent] {
    let store = CalendarService.shared.store
    let now = Date()
    let endDate = now.addingTimeInterval(lookahead)

    let predicate = store.predicateForEvents(
        withStart: now,
        end: endDate,
        calendars: calendars // nil = all calendars
    )

    return store.events(matching: predicate)
        .sorted { $0.startDate < $1.startDate }
}
```

### Getting Calendar List for Settings

```swift
// Source: EventKit documentation
func getEventCalendars() -> [EKCalendar] {
    let store = CalendarService.shared.store
    return store.calendars(for: .event)
}

// Store user preferences
func saveEnabledCalendarIDs(_ ids: Set<String>) {
    UserDefaults.standard.set(Array(ids), forKey: "enabledCalendarIDs")
}

func loadEnabledCalendarIDs() -> Set<String>? {
    guard let array = UserDefaults.standard.array(forKey: "enabledCalendarIDs") as? [String] else {
        return nil // nil means all enabled (default)
    }
    return Set(array)
}
```

### Relative Time Formatting

```swift
// Source: DateComponentsFormatter documentation
func formatRelativeTime(until date: Date, from now: Date = Date()) -> String {
    let interval = date.timeIntervalSince(now)

    guard interval > 0 else { return "now" }

    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated
    formatter.maximumUnitCount = 1

    guard let formatted = formatter.string(from: interval) else {
        return "soon"
    }

    return "in \(formatted)"
}

// Examples:
// 45 minutes -> "in 45m"
// 2 hours -> "in 2h"
// 90 minutes -> "in 1h" (maximumUnitCount = 1)
```

### Menu Bar Display with Truncation

```swift
// Source: CONTEXT.md decision (20-25 chars)
func formatMenuBarText(event: EKEvent, now: Date) -> String {
    if event.isAllDay {
        let title = truncate(event.title, maxLength: 20)
        return "\(title) - Today"
    }

    let timeText = formatRelativeTime(until: event.startDate, from: now)
    let title = truncate(event.title, maxLength: 20)
    return "\(title) \(timeText)"
}

func truncate(_ string: String, maxLength: Int) -> String {
    guard string.count > maxLength else { return string }
    let endIndex = string.index(string.startIndex, offsetBy: maxLength - 1)
    return String(string[..<endIndex]) + "..."
}
```

### Dark Mode Support

```swift
// Source: SwiftUI colorScheme documentation
struct MenuBarView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        // SwiftUI handles this automatically for system colors
        // Use Color.primary, Color.secondary for text
        // Use asset catalog colors with dark mode variants
        Text("Event title")
            .foregroundStyle(.primary) // Auto-adapts to light/dark
    }
}

// For calendar color dot - CGColor from EKCalendar
// No dark mode adjustment needed (calendar colors are user-defined)
```

### System Settings Deep Link

```swift
// Source: macOS deep link patterns
func openPrivacySettings() {
    // macOS Ventura+ (System Settings)
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
        NSWorkspace.shared.open(url)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| requestAccess(to:) | requestFullAccessToEvents() | macOS 14 | Must support both for macOS 13 compat |
| NSStatusItem + AppDelegate | MenuBarExtra scene | macOS 13 | Eliminates AppKit bridging |
| @StateObject | @Observable | macOS 14 | Simpler syntax, but requires availability check |
| Timer.publish | TimelineView | Available since macOS 12 | Battery efficient, works in MenuBarExtra |
| Preferences scene name | Settings scene name | macOS 13 | Automatic, cosmetic only |

**Deprecated/outdated:**
- `requestAccess(to:completion:)`: Still works but deprecated on macOS 14+
- `NSCalendarsUsageDescription` alone: Insufficient on macOS 14+, need NSCalendarsFullAccessUsageDescription
- `showPreferencesWindow:` private selector: No longer works on macOS 14+

## Open Questions

1. **Icon in menu bar (optional per CONTEXT.md)**
   - What we know: Users can toggle icon visibility
   - What's unclear: Should default be icon+text or text only?
   - Recommendation: Default to text only (saves menu bar space), icon as user setting

2. **Lookahead window configuration**
   - What we know: User can configure, default 24 hours
   - What's unclear: What are reasonable min/max bounds?
   - Recommendation: Min 1 hour, max 7 days, default 24 hours

3. **Permission denied recovery**
   - What we know: Show instructions with "Open Settings" button
   - What's unclear: How often to re-check if user enables in settings?
   - Recommendation: Check on app activation (NSApplication.didBecomeActiveNotification)

## Sources

### Primary (HIGH confidence)
- [Apple EventKit Documentation](https://developer.apple.com/documentation/eventkit) - EKEventStore, permissions, events
- [Apple MenuBarExtra Documentation](https://developer.apple.com/documentation/swiftui/menubarextra) - Scene type, styles
- [Apple TimelineView Documentation](https://developer.apple.com/documentation/swiftui/timelineview) - Periodic updates
- [Filip Nemecek: EventKit Change Notifications](https://nemecek.be/blog/63/how-to-monitor-system-calendar-for-changes-with-eventkit) - Implementation pattern

### Secondary (MEDIUM confidence)
- [Nil Coalescing: Build a macOS menu bar utility](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/) - MenuBarExtra patterns
- [Peter Steinberger: Showing Settings from Menu Bar Items](https://steipete.me/posts/2025/showing-settings-from-macos-menu-bar-items) - Settings workarounds
- [Wesley Matlock: TimelineView for Time-Based Updates](https://medium.com/@wesleymatlock/utilizing-timelineview-for-time-based-updates-in-swiftui-432fca93da03) - Timer alternatives
- [sindresorhus/Settings GitHub](https://github.com/sindresorhus/Settings) - Preferences package

### Tertiary (LOW confidence)
- Apple Developer Forums thread on SwiftUI Timer in MenuBarExtra - Confirms runloop blocking issue

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Apple frameworks, well-documented
- Architecture: HIGH - Patterns validated in existing research
- Pitfalls: HIGH - Multiple sources confirm same issues
- Code examples: MEDIUM - Compiled from official docs and tutorials, not runtime tested

**Research date:** 2026-01-24
**Valid until:** 2026-02-24 (30 days - stable APIs)

---
*Phase: 01-core-menu-bar-local-calendar*
*Research completed: 2026-01-24*
