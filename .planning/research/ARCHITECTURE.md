# Architecture Research

**Domain:** macOS menu bar app with calendar integration
**Researched:** 2026-01-24
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ MenuBarExtra │  │  NSStatusBar │  │   NSPopover  │       │
│  │   (SwiftUI)  │  │     Item     │  │  /NSMenu     │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
│         │                 │                 │               │
├─────────┴─────────────────┴─────────────────┴───────────────┤
│                     STATE LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │        AppState (@Observable / ObservableObject)    │    │
│  │  - Current Event                                    │    │
│  │  - Upcoming Events List                             │    │
│  │  - Urgency State                                    │    │
│  │  - Timer State                                      │    │
│  └───────────────────┬─────────────────────────────────┘    │
│                      │                                       │
├──────────────────────┴───────────────────────────────────────┤
│                   SERVICE LAYER                              │
├─────────────────────────────────────────────────────────────┤
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │  Calendar  │  │   Timer    │  │Notification│             │
│  │  Service   │  │  Manager   │  │  Service   │             │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘             │
│        │               │               │                    │
├────────┴───────────────┴───────────────┴────────────────────┤
│                   DATA LAYER                                 │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐  ┌───────────┐                │
│  │ EventKit  │  │  Google   │  │  Outlook  │                │
│  │   Store   │  │ Calendar  │  │ Calendar  │                │
│  │           │  │    API    │  │    API    │                │
│  └───────────┘  └───────────┘  └───────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| MenuBarExtra | Menu bar UI entry point (macOS 13+) | SwiftUI scene, system integration |
| NSStatusBar Item | Legacy menu bar integration | AppKit NSStatusItem, works all macOS versions |
| NSPopover/NSMenu | Dropdown UI display | NSPopover for rich content, NSMenu for native feel |
| AppState | Central state holder | @Observable class or ObservableObject with @Published properties |
| CalendarService | Calendar data fetching, caching | EventKit wrapper + external API clients |
| TimerManager | Real-time countdown updates | Timer with tolerance, main thread updates |
| NotificationService | Push notifications | UserNotifications framework |
| EventKit Store | Local calendar access | EKEventStore singleton |
| External API Clients | Google/Outlook integration | OAuth2 + REST API clients |

## Recommended Project Structure

```
ToEvent/
├── App/
│   ├── ToEventApp.swift           # Main app entry, MenuBarExtra scene
│   └── AppDelegate.swift          # (Optional) System events, legacy support
├── Views/
│   ├── MenuBarView.swift          # Status item content (time, event name)
│   ├── PopoverView.swift          # Dropdown content (event list)
│   └── Components/
│       ├── EventRow.swift         # Single event display
│       └── UrgencyIndicator.swift # Color-coded warning
├── State/
│   └── AppState.swift             # @Observable central state
├── Services/
│   ├── CalendarService.swift     # Calendar data orchestration
│   ├── TimerManager.swift        # Countdown timer logic
│   ├── NotificationService.swift # Push notification handler
│   └── Providers/
│       ├── EventKitProvider.swift    # Local calendar access
│       ├── GoogleCalendarProvider.swift  # Google API
│       └── OutlookCalendarProvider.swift # Outlook API
├── Models/
│   ├── Event.swift               # Unified event model
│   ├── CalendarSource.swift      # EventKit, Google, Outlook enum
│   └── UrgencyLevel.swift        # Color coding logic
└── Utilities/
    ├── DateHelpers.swift         # Time calculations
    └── EventMonitor.swift        # Click-outside-popover detection
```

### Structure Rationale

- **App/:** Application lifecycle, system integration, delegate pattern for background tasks
- **Views/:** SwiftUI-first, composable UI components, separation of menu bar vs popover concerns
- **State/:** Single source of truth, @Observable for modern SwiftUI (macOS 14+) or ObservableObject for compatibility
- **Services/:** Business logic isolation, testable, provider pattern for multiple calendar sources
- **Models/:** Platform-agnostic data structures, unified interface over EventKit/Google/Outlook
- **Utilities/:** Cross-cutting concerns, reusable helpers

## Architectural Patterns

### Pattern 1: Service Provider Pattern

**What:** Abstract calendar access behind provider protocol, swap implementations per source

**When to use:** Multiple external integrations (EventKit, Google, Outlook) with similar operations

**Trade-offs:**
- **Pro:** Easy to add new providers, testable with mocks, clean separation
- **Con:** Extra indirection, may be overkill if only using EventKit

**Example:**
```swift
protocol CalendarProvider {
  func fetchEvents(from: Date, to: Date) async throws -> [Event]
  func startMonitoring(onChange: @escaping () -> Void)
}

class EventKitProvider: CalendarProvider {
  private let store = EKEventStore()

  func fetchEvents(from: Date, to: Date) async throws -> [Event] {
    let predicate = store.predicateForEvents(withStart: from, end: to, calendars: nil)
    let ekEvents = store.events(matching: predicate)
    return ekEvents.map { Event(from: $0) }
  }

  func startMonitoring(onChange: @escaping () -> Void) {
    NotificationCenter.default.addObserver(
      forName: .EKEventStoreChanged,
      object: store,
      queue: .main
    ) { _ in onChange() }
  }
}
```

### Pattern 2: Observable State Container

**What:** Single @Observable class holding all app state, used across views and services

**When to use:** SwiftUI apps with multiple views sharing state, real-time updates

**Trade-offs:**
- **Pro:** Automatic UI updates, simple data flow, single source of truth
- **Con:** Can grow large, temptation to put logic in state vs services

**Example:**
```swift
@Observable
class AppState {
  var currentEvent: Event?
  var upcomingEvents: [Event] = []
  var timeRemaining: TimeInterval = 0
  var urgencyLevel: UrgencyLevel = .normal

  // Computed, updates UI automatically
  var displayText: String {
    guard let event = currentEvent else { return "No events" }
    let minutes = Int(timeRemaining / 60)
    return "\(minutes)m - \(event.title)"
  }
}
```

### Pattern 3: Timer with Tolerance for Battery Efficiency

**What:** Use Timer with tolerance property to allow system coalescing, reduce CPU wake-ups

**When to use:** Real-time updates (every second) in menu bar apps

**Trade-offs:**
- **Pro:** Better battery life, system can batch timer events
- **Con:** Updates may not be exactly on-the-second (acceptable for countdown display)

**Example:**
```swift
class TimerManager {
  private var timer: Timer?
  private let updateInterval: TimeInterval = 1.0

  func startTimer(onTick: @escaping () -> Void) {
    timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
      onTick()
    }
    // Critical for battery: allow 0.5s variance
    timer?.tolerance = 0.5
  }
}
```

### Pattern 4: Notification-Based Calendar Sync

**What:** Subscribe to EKEventStoreChanged, reload on notification rather than polling

**When to use:** EventKit integration, need to detect external calendar changes

**Trade-offs:**
- **Pro:** Battery efficient, no polling overhead, immediate updates
- **Con:** Notification has no diff info, requires full reload

**Example:**
```swift
class EventKitProvider {
  func startMonitoring(onChange: @escaping () -> Void) {
    NotificationCenter.default.publisher(for: .EKEventStoreChanged)
      .sink { _ in
        onChange() // Full reload required
      }
      .store(in: &cancellables)
  }
}
```

### Pattern 5: FocusedBinding for Menu Bar Communication

**What:** Use @FocusedBinding + focusedSceneValue to communicate between menu bar commands and SwiftUI views

**When to use:** Custom menu bar commands that need to target active window/view

**Trade-offs:**
- **Pro:** Properly targets active scene, works with tabbed windows, modern API
- **Con:** More boilerplate than simple closures, requires understanding focused values

**Example:**
```swift
// 1. Define focused value key
struct EventActionsKey: FocusedValueKey {
  typealias Value = EventActions
}

extension FocusedValues {
  var eventActions: EventActionsKey.Value? {
    get { self[EventActionsKey.self] }
    set { self[EventActionsKey.self] = newValue }
  }
}

// 2. Set in view
struct PopoverView: View {
  @State private var actions = EventActions()

  var body: some View {
    EventList()
      .focusedSceneValue(\.eventActions, actions)
  }
}

// 3. Access in App
@main
struct ToEventApp: App {
  @FocusedBinding(\.eventActions) var actions

  var body: some Scene {
    MenuBarExtra { /* ... */ }
      .commands {
        CommandMenu("Events") {
          Button("Refresh") { actions?.refresh() }
        }
      }
  }
}
```

## Data Flow

### Real-Time Update Flow

```
Timer (1s interval)
    ↓
TimerManager.tick()
    ↓
AppState.updateTimeRemaining()
    ↓
MenuBarView (auto-updates via @Observable)
    ↓
NSStatusItem.button?.title = appState.displayText
```

### Calendar Fetch Flow

```
App Launch / EKEventStoreChanged Notification
    ↓
CalendarService.refreshEvents()
    ↓
[EventKitProvider, GoogleProvider, OutlookProvider].fetchEvents()
    ↓ (async parallel)
Merge results → AppState.upcomingEvents
    ↓
AppState.currentEvent = upcomingEvents.first
    ↓
PopoverView updates (SwiftUI observes AppState)
```

### External Calendar Integration Flow

```
User enables Google Calendar
    ↓
GoogleCalendarProvider.authenticate() (OAuth 2.0)
    ↓
Store tokens in Keychain
    ↓
CalendarService.addProvider(GoogleCalendarProvider)
    ↓
Background refresh every N minutes (configurable)
    ↓
Fetch events via Google Calendar API
    ↓
Convert to unified Event model
    ↓
Merge with EventKit events → AppState
```

### Key Data Flows

1. **Startup:** Request EventKit permission → Fetch events → Start timer → Display current event
2. **Background refresh:** Timer fires every N minutes → Fetch from all providers → Merge → Update state
3. **External change:** EKEventStoreChanged notification → Full reload → Update state
4. **UI interaction:** User clicks menu bar → Show popover → Display upcoming events list
5. **Notification:** Event starts in 5 minutes → NotificationService.send() → System notification

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Single user | Current architecture sufficient, in-memory state, no persistence |
| Multiple calendar accounts (3-5) | Add account management UI, per-account providers, settings persistence |
| 100+ events per day | Add pagination to popover, cache events in UserDefaults/CoreData, limit fetch window |
| Real-time collaboration | WebSocket for Google/Outlook changes, conflict resolution strategy |

### Scaling Priorities

1. **First bottleneck:** EventKit full reload on every change
   - **Fix:** Implement incremental cache diff, only update changed events
   - **When:** User has 50+ events and notices lag

2. **Second bottleneck:** Multiple API calls per refresh
   - **Fix:** Background URLSession with consolidation, rate limiting per provider
   - **When:** User adds 3+ external calendars and battery drain increases

3. **Third bottleneck:** Menu bar update frequency (every second)
   - **Fix:** Only update when display text actually changes (e.g., minute boundary)
   - **When:** Battery profiling shows timer as top energy consumer

## Anti-Patterns

### Anti-Pattern 1: Polling EventKit Instead of Notifications

**What people do:** Set up Timer to re-fetch EventKit events every 30 seconds

**Why it's wrong:**
- Battery drain from unnecessary CPU wake-ups
- EKEventStoreChanged notification exists specifically for this
- No benefit over notification-based approach

**Do this instead:** Subscribe to EKEventStoreChanged and reload only when notification fires

### Anti-Pattern 2: Creating Multiple EKEventStore Instances

**What people do:** Instantiate new EKEventStore() in each provider or service method

**Why it's wrong:**
- Apple documentation explicitly warns against this
- Performance degradation, memory overhead
- Permission requests may not persist correctly

**Do this instead:** Create singleton EKEventStore, reuse across app lifetime

### Anti-Pattern 3: UI Updates from Background Thread

**What people do:** Update AppState properties from Timer or async calendar fetch without @MainActor

**Why it's wrong:**
- SwiftUI updates must happen on main thread
- Crashes or undefined behavior
- Purple runtime warnings in console

**Do this instead:**
```swift
@Observable
@MainActor
class AppState {
  // All updates automatically on main thread
}

// Or in service:
Task { @MainActor in
  appState.upcomingEvents = events
}
```

### Anti-Pattern 4: Using NSPopover for Everything

**What people do:** Default to NSPopover because tutorials show it, use for all menu bar UI

**Why it's wrong:**
- Unnatural dismiss behavior (click-outside doesn't always work)
- Slight delay on open
- Doesn't feel like native menu bar app
- Known focus issues from menu bar

**Do this instead:** Consider NSMenu with SwiftUI hosting for simpler UIs, NSPanel for complex UIs, NSPopover only when you need the arrow/pointer aesthetic

### Anti-Pattern 5: No Timer Tolerance

**What people do:** Create Timer without setting tolerance property

**Why it's wrong:**
- Prevents system timer coalescing
- Battery drain from precise wake-ups every second
- No user-visible benefit (countdown doesn't need millisecond precision)

**Do this instead:** Always set timer.tolerance = 0.3 to 0.5 seconds for 1-second intervals

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| EventKit | Singleton store + NotificationCenter | Requires NSCalendarsFullAccessUsageDescription in Info.plist |
| Google Calendar API | OAuth 2.0 + REST API | Use GoogleSignIn SDK, Calendar API v3, requires client ID from Console |
| Microsoft Graph (Outlook) | OAuth 2.0 + REST API | Azure app registration, Calendars.ReadWrite scope, supports shared calendars |
| UserNotifications | Framework integration | Request authorization on first launch, handle notification responses |
| Keychain | Credentials storage | Store OAuth tokens, use keychain-swift or native Security framework |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| AppState ↔ Services | Services update state via @MainActor methods | One-way: services push to state, state doesn't call services |
| Views ↔ AppState | SwiftUI observation (@Observable) | Automatic: views re-render when state changes |
| CalendarService ↔ Providers | Protocol-based async calls | Parallel fetching: Task.group for multiple providers |
| TimerManager ↔ AppState | Closure callback | TimerManager has no state, just triggers callback |
| MenuBarExtra ↔ AppDelegate | focusedSceneValue or environment | Use for custom menu commands, system events |

## Build Order Implications

Suggested component build order based on dependencies:

### Phase 1: Core Infrastructure
1. **Models** (Event, UrgencyLevel) - No dependencies
2. **AppState** - Depends on models
3. **Basic MenuBarView** - Static display, no real data

### Phase 2: Local Calendar
4. **EventKitProvider** - First data source
5. **CalendarService** - Orchestrates provider
6. **Wire AppState ↔ CalendarService** - Display real events

### Phase 3: Real-Time Updates
7. **TimerManager** - Countdown logic
8. **Update MenuBarView** - Live countdown display
9. **UrgencyIndicator** - Color coding

### Phase 4: Dropdown UI
10. **PopoverView / NSMenu** - Event list display
11. **EventRow component** - Reusable list item

### Phase 5: External Calendars
12. **GoogleCalendarProvider** - OAuth + API
13. **OutlookCalendarProvider** - OAuth + API
14. **Settings UI** - Enable/disable providers

### Phase 6: Notifications
15. **NotificationService** - Push reminders
16. **Background refresh** - Periodic fetch

**Ordering rationale:**
- Models first (no dependencies, used everywhere)
- Local calendar before external (simpler, validates architecture)
- Timer after data (needs events to count down)
- UI progressive enhancement (menu bar → popover → notifications)
- External APIs last (most complex, requires OAuth plumbing)

## Sources

**macOS Menu Bar Architecture:**
- [Create a mac menu bar app in SwiftUI with MenuBarExtra | Sarunw](https://sarunw.com/posts/swiftui-menu-bar-app/)
- [Build a macOS menu bar utility in SwiftUI](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/)
- [Exploring MacOS Development: Creating a Menu Bar App with Swift & SwiftUI](https://capgemini.github.io/development/macos-development-with-swift/)

**State Management & Communication:**
- [The Mac Menubar and SwiftUI - TrozWare](https://troz.net/post/2025/mac_menu_data/) (2025, HIGH confidence)
- [Customizing the macOS menu bar in SwiftUI](https://danielsaidi.com/blog/2023/11/22/customizing-the-macos-menu-bar-in-swiftui)

**EventKit Integration:**
- [How to monitor system calendar for changes with EventKit | Filip Němeček](https://nemecek.be/blog/63/how-to-monitor-system-calendar-for-changes-with-eventkit) (HIGH confidence)
- [EventKit | Apple Developer Documentation](https://developer.apple.com/documentation/eventkit)
- [Manage calendar events with EventKit and EventKitUI with Swift](https://medium.com/@fede_nieto/manage-calendar-events-with-eventkit-and-eventkitui-with-swift-74e1ecbe2524)

**Timer & Battery Efficiency:**
- [Energy Efficiency Guide for Mac Apps: Minimize Timer Usage](https://developer.apple.com/library/archive/documentation/Performance/Conceptual/power_efficiency_guidelines_osx/Timers.html) (Apple official, HIGH confidence)
- [Swift Timer Best Practices: Tips and Tricks for Optimal Performance](https://vikramios.medium.com/swift-timer-24149096c0db)

**NSPopover & UI Patterns:**
- [What I Learned Building a Native macOS Menu Bar App](https://dev.to/heocoi/what-i-learned-building-a-native-macos-menu-bar-app-4im6)
- [Menus and Popovers in Menu Bar Apps for macOS | Kodeco](https://www.kodeco.com/450-menus-and-popovers-in-menu-bar-apps-for-macos)

**External Calendar APIs:**
- [GitHub - mipar52/google-examples-swift](https://github.com/mipar52/google-examples-swift) (2025 SwiftUI examples)
- [Outlook calendar API overview - Microsoft Graph](https://learn.microsoft.com/en-us/graph/outlook-calendar-concept-overview)

---
*Architecture research for: ToEvent macOS menu bar app*
*Researched: 2026-01-24*
