# Phase 3: Dropdown Event List - Research

**Researched:** 2026-01-24
**Domain:** SwiftUI MenuBarExtra dropdown with event list, dynamic sizing, AppleScript Calendar integration
**Confidence:** HIGH (most patterns verified with official docs and existing codebase)

## Summary

This phase builds on the existing MenuBarExtra (.window style) infrastructure to create a dropdown showing upcoming events. The codebase already has CalendarService fetching multiple events, but only displays the first one. The primary work is: (1) exposing the full event list in AppState, (2) building a VStack-based event list with rows styled like Apple Reminders, (3) implementing grow-to-fit dynamic height, and (4) integrating AppleScript to open events in Calendar.app.

The key architectural decision from CONTEXT.md is "grow to fit content" rather than fixed-height scrollable. This means using VStack with ForEach rather than List/ScrollView, and letting the MenuBarExtra window size itself to content. For opening events in Calendar, AppleScript's `show` command is the only reliable method; URL schemes like `calshow://` and `x-apple-calevent://` do not work for specific events.

**Primary recommendation:** Use VStack with ForEach for the event list (not List/LazyVStack), AppleScript via NSAppleScript to open events in Calendar, and frame constraints to allow dynamic sizing.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI MenuBarExtra | macOS 13+ | Dropdown window | Already in use, .window style |
| EventKit | macOS 13+ | Calendar data | Already integrated via CalendarService |
| NSAppleScript | macOS 13+ | Open events in Calendar.app | Only reliable way to show specific events |
| AppKit (NSWorkspace) | macOS 13+ | Open Settings window | Already in use |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| MenuBarExtraAccess | 1.0+ | Status item customization | Already integrated, not needed for dropdown |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| VStack | List | List adds unwanted selection behavior, row backgrounds conflict with macOS highlight; VStack gives full control |
| VStack | LazyVStack | Lazy loading irrelevant for <50 events; LazyVStack has worse memory management than List |
| AppleScript | calshow:// URL | URL scheme only opens app, cannot navigate to specific event |

**Installation:**
No additional packages required. All tools are built-in or already installed.

## Architecture Patterns

### Recommended Project Structure
```
Views/
├── MenuBarView.swift          # Existing, refactor to container
├── EventListView.swift        # New: VStack-based event list
├── EventRowView.swift         # New: individual row with hover/press
├── DropdownFooterView.swift   # New: gear + refresh buttons
└── DateHeaderView.swift       # New: "Tomorrow" header for fallback
```

### Pattern 1: VStack Event List with Dividers
**What:** Use VStack with ForEach and explicit Divider views between rows
**When to use:** When you need full control over row appearance and no selection behavior
**Example:**
```swift
// Source: Apple Divider documentation + research
VStack(spacing: 0) {
    ForEach(events.indices, id: \.self) { index in
        EventRowView(event: events[index])
        if index < events.count - 1 {
            Divider()
                .padding(.horizontal, 12)
        }
    }
}
```

### Pattern 2: Dynamic Height MenuBarExtra Window
**What:** Allow window to grow with content using frame constraints
**When to use:** When dropdown should show all content without scrolling
**Example:**
```swift
// Source: nilcoalescing.com MenuBarExtra guide
MenuBarExtra {
    ContentView()
        .frame(width: 280)  // Fixed width, flexible height
        .fixedSize(horizontal: false, vertical: true)  // Respect intrinsic height
}
.menuBarExtraStyle(.window)
```

### Pattern 3: Hover + Pressed Row States
**What:** Track hover and pressed states for interactive row feedback
**When to use:** For clickable rows that need visual feedback
**Example:**
```swift
// Source: Swift with Majid hover effects + research
struct EventRowView: View {
    let event: Event
    @State private var isHovered = false

    var body: some View {
        Button(action: openInCalendar) {
            rowContent
        }
        .buttonStyle(EventRowButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct EventRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Color.accentColor.opacity(0.2) :
                Color.clear
            )
    }
}
```

### Pattern 4: AppleScript Calendar Integration
**What:** Use NSAppleScript to show events in Calendar.app
**When to use:** When user clicks an event to open it
**Example:**
```swift
// Source: Apple Calendar Scripting Guide
func openEventInCalendar(event: Event, calendarTitle: String) {
    let script = """
    tell application "Calendar"
        tell calendar "\(calendarTitle)"
            show (first event where its uid = "\(event.id)")
        end tell
        activate
    end tell
    """
    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: script) {
        scriptObject.executeAndReturnError(&error)
    }
}
```

### Pattern 5: Fixed Footer Bar
**What:** Use VStack with Spacer or explicit layout to pin footer at bottom
**When to use:** For persistent actions (gear, refresh) below content
**Example:**
```swift
// Source: Standard SwiftUI layout patterns
VStack(spacing: 0) {
    // Event list content
    eventList

    Divider()

    // Fixed footer
    HStack {
        Button(action: openSettings) {
            Image(systemName: "gear")
        }
        Spacer()
        Button(action: refresh) {
            Image(systemName: "arrow.clockwise")
        }
    }
    .padding(8)
}
```

### Anti-Patterns to Avoid
- **Using List for event rows:** List adds unwanted selection behavior and row backgrounds that conflict with macOS highlight states. Use VStack with ForEach instead.
- **Using ScrollView when content fits:** CONTEXT.md specifies grow-to-fit; don't add scroll when content is small.
- **Using URL schemes for Calendar:** `calshow://` and `x-apple-calevent://` don't work for opening specific events. Use AppleScript.
- **Calling refreshEvents() on every row render:** Cache the events list in AppState, not in individual views.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Opening events in Calendar.app | URL scheme attempts | AppleScript `show` command | URL schemes don't work for specific events; AppleScript is the only documented solution |
| Time formatting | Custom date arithmetic | DateFormatters.formatHybridCountdown | Already exists in codebase, handles all edge cases |
| Calendar colors | CGColor manipulation | Color(cgColor:) | SwiftUI handles color space conversion |
| Settings window | Custom Window scene | NSApp.sendAction showSettingsWindow | Already works in existing MenuBarView |

**Key insight:** The codebase already has most utilities needed. The Event model, CalendarService, DateFormatters, and UrgencyLevel are all ready. Focus on UI composition, not reimplementing data handling.

## Common Pitfalls

### Pitfall 1: MenuBarExtra Window Height Not Updating
**What goes wrong:** Window stays fixed size when content changes
**Why it happens:** SwiftUI doesn't automatically resize MenuBarExtra windows
**How to avoid:** Use `.fixedSize(horizontal: false, vertical: true)` on root view; avoid explicit height constraints
**Warning signs:** Window crops content or has empty space

### Pitfall 2: AppleScript Requires Calendar Title, Not ID
**What goes wrong:** AppleScript fails to find calendar
**Why it happens:** AppleScript uses human-readable calendar title, not calendarIdentifier
**How to avoid:** Store calendar title in Event model alongside calendarID; fetch from CalendarInfo
**Warning signs:** "Event not found" errors in AppleScript

### Pitfall 3: List Row Background Conflicts with Selection
**What goes wrong:** Calendar color tint draws over system selection highlight
**Why it happens:** `listRowBackground` doesn't respect selection state on macOS
**How to avoid:** Use VStack with ForEach instead of List; implement custom highlight state
**Warning signs:** Blue selection highlight hidden behind tint color

### Pitfall 4: Events Not Filtered After Start
**What goes wrong:** Past events still appear in list
**Why it happens:** CalendarService predicate uses `now` at fetch time, not display time
**How to avoid:** Filter events in view with `event.startDate > Date()` or based on lifecycle setting
**Warning signs:** Events marked "Now" persisting in list

### Pitfall 5: Hover State Persists After Click
**What goes wrong:** Row stays highlighted after clicking
**Why it happens:** onHover doesn't automatically reset when menu closes
**How to avoid:** Reset hover state in Button action; consider using ButtonStyle for cleaner state management
**Warning signs:** Multiple rows appearing hovered

### Pitfall 6: AppleScript Permissions on Catalina+
**What goes wrong:** AppleScript fails silently or with -600 error
**Why it happens:** macOS requires explicit automation permissions
**How to avoid:** Add `com.apple.security.automation.apple-events` entitlement; add `NSAppleEventsUsageDescription` to Info.plist
**Warning signs:** Script executes without error but Calendar doesn't respond

## Code Examples

Verified patterns from official sources and codebase analysis:

### Event List with All-Day Grouping
```swift
// Source: CONTEXT.md decision - all-day events grouped at top
var allDayEvents: [Event] {
    events.filter { $0.isAllDay }
}

var timedEvents: [Event] {
    events.filter { !$0.isAllDay }
}

var body: some View {
    VStack(spacing: 0) {
        ForEach(allDayEvents) { event in
            EventRowView(event: event)
        }
        if !allDayEvents.isEmpty && !timedEvents.isEmpty {
            Divider()
        }
        ForEach(timedEvents) { event in
            EventRowView(event: event)
        }
    }
}
```

### Subtle Calendar Color Background Tint
```swift
// Source: CONTEXT.md decision - subtle background tint
EventRowView(event: event)
    .background(Color(cgColor: event.calendarColor).opacity(0.1))
```

### Tomorrow Fallback with Date Header
```swift
// Source: CONTEXT.md decision - fall back to tomorrow when no events today
var body: some View {
    if todayEvents.isEmpty && !tomorrowEvents.isEmpty {
        VStack(alignment: .leading, spacing: 0) {
            Text("Tomorrow")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            ForEach(tomorrowEvents) { event in
                EventRowView(event: event)
            }
        }
    } else if !todayEvents.isEmpty {
        ForEach(todayEvents) { event in
            EventRowView(event: event)
        }
    } else {
        Text("All clear")
            .foregroundStyle(.secondary)
    }
}
```

### Refresh Button with Spin Animation
```swift
// Source: Standard SwiftUI animation patterns
@State private var isRefreshing = false

Button(action: {
    withAnimation(.linear(duration: 0.5)) {
        isRefreshing = true
    }
    appState.refreshEvents()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isRefreshing = false
    }
}) {
    Image(systemName: "arrow.clockwise")
        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
}
```

### Open Event in Calendar with AppleScript
```swift
// Source: Apple Calendar Scripting Guide
func openEventInCalendar() {
    guard let calendarTitle = calendarTitle(for: event.calendarID) else { return }

    // Escape quotes in calendar title and event ID
    let escapedTitle = calendarTitle.replacingOccurrences(of: "\"", with: "\\\"")
    let script = """
    tell application "Calendar"
        tell calendar "\(escapedTitle)"
            show (first event where its uid = "\(event.id)")
        end tell
        activate
    end tell
    """

    var error: NSDictionary?
    if let scriptObject = NSAppleScript(source: script) {
        scriptObject.executeAndReturnError(&error)
        if let error = error {
            print("AppleScript error: \(error)")
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| List with listRowBackground | VStack with ForEach | macOS 13+ | Better control over row styling on macOS |
| calshow:// URL scheme | AppleScript show command | Never worked | Only reliable way to open specific events |
| Fixed MenuBarExtra height | Dynamic content-sized window | macOS 13+ | Grow-to-fit is now possible |

**Deprecated/outdated:**
- `x-apple-calevent://` URL scheme: Never reliably worked, returns "no application set to open" error
- `calshow://` for specific events: Only opens Calendar app, doesn't navigate to event
- TimelineView for dropdown content: Timer-based updates preferred per Phase 2 decision

## Open Questions

Things that couldn't be fully resolved:

1. **Calendar title storage**
   - What we know: AppleScript needs calendar title (human-readable), not calendarIdentifier
   - What's unclear: Whether to add calendarTitle to Event model or fetch on demand from CalendarInfo
   - Recommendation: Fetch CalendarInfo once when building event list, pass title to row view

2. **Event lifecycle configuration**
   - What we know: CONTEXT.md says "configurable (remove at start, keep until end, or manual)"
   - What's unclear: Where to store this preference, how to expose in settings
   - Recommendation: Add to GeneralSettingsView in this phase or defer to Phase 4 customization

3. **Keyboard navigation**
   - What we know: CONTEXT.md lists as "Claude's Discretion", SwiftUI keyboard nav has known issues
   - What's unclear: Whether to invest in arrow key navigation or stay mouse-only
   - Recommendation: Mouse-only for this phase; keyboard nav has poor SwiftUI support and low ROI

4. **Maximum events limit**
   - What we know: "Show all of today's remaining events" could be many events
   - What's unclear: Performance with 20+ events, visual overflow off screen
   - Recommendation: Start unlimited, add "show more" if testing reveals issues

## Sources

### Primary (HIGH confidence)
- Existing codebase: ToEventApp.swift, MenuBarView.swift, AppState.swift, Event.swift, CalendarService.swift
- [Apple Calendar Scripting Guide: Revealing an Event](https://developer.apple.com/library/archive/documentation/AppleApplications/Conceptual/CalendarScriptingGuide/Calendar-RevealanEvent.html)
- [Apple Developer: MenuBarExtra](https://developer.apple.com/documentation/swiftui/menubarextra)
- [Apple Developer: Divider](https://developer.apple.com/documentation/swiftui/divider)

### Secondary (MEDIUM confidence)
- [nilcoalescing.com: Build a macOS menu bar utility in SwiftUI](https://nilcoalescing.com/blog/BuildAMacOSMenuBarUtilityInSwiftUI/)
- [Swift with Majid: Hover effect in SwiftUI](https://swiftwithmajid.com/2020/03/25/hover-effect-in-swiftui/)
- [Hacking with Swift: listRowBackground](https://www.hackingwithswift.com/quick-start/swiftui/how-to-set-the-background-color-of-list-rows-using-listrowbackground)
- [Sarunw: SwiftUI Divider](https://sarunw.com/posts/swiftui-divider/)

### Tertiary (LOW confidence)
- WebSearch results on URL schemes (all indicated calshow/x-apple-calevent don't work reliably)
- WebSearch results on List vs LazyVStack performance (tested on other datasets, not calendar events)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already in codebase or built-in macOS
- Architecture: HIGH - Patterns verified with official docs and existing code
- Pitfalls: MEDIUM - AppleScript permissions untested in this app, inferred from docs
- Calendar opening: HIGH - AppleScript method verified in Apple Scripting Guide

**Research date:** 2026-01-24
**Valid until:** 2026-02-24 (30 days - stable SwiftUI/macOS patterns)
