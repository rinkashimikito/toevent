# Phase 6: Meeting Links + Notifications - Research

**Researched:** 2026-01-24
**Domain:** UNUserNotificationCenter, MapKit travel time, meeting URL detection, Focus mode integration
**Confidence:** MEDIUM (verified with official docs, macOS Focus mode APIs have gaps)

## Summary

This phase adds one-click meeting join, location-based actions (directions, travel time), event reminders with snooze, and system integrations (Focus mode filtering, conflict warnings). The research reveals that macOS notification handling requires UNUserNotificationCenter (NSUserNotification deprecated in macOS 11), meeting URLs must be extracted from multiple event sources (EventKit, Google conferenceData, Microsoft onlineMeeting), and Focus mode detection is limited to implementing a FocusFilterIntent rather than querying current state.

The Event model needs extension to include `location`, `meetingURL`, and parsed URLs from event descriptions/notes. MapKit's `MKDirections.calculateETA()` provides travel time, and notifications can include custom actions for snooze functionality.

**Primary recommendation:** Extend the Event model with location/URL fields, implement a NotificationService with UNUserNotificationCenter and custom categories for snooze actions, use MapKit for travel time calculation, and add a FocusFilterIntent for Focus mode integration.

## Standard Stack

The established libraries/tools for this domain:

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UserNotifications | System | UNUserNotificationCenter for local notifications | Apple replacement for deprecated NSUserNotification |
| MapKit | System | MKDirections for travel time ETA | Apple-provided, integrates with Maps |
| AppIntents | System | Focus filter implementation | Required for Focus mode integration |
| EventKit | System | EKEvent location/URL properties | Already in use, has structuredLocation |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| AudioToolbox | System | Custom notification sounds | AudioServicesPlaySystemSound for alerts |
| CoreLocation | System | CLLocation for geo-coordinates | For structured location handling |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| UNUserNotificationCenter | NSUserNotification | Deprecated in macOS 11, avoid |
| MKDirections | Apple Maps Server API | Server API has quotas, MKDirections is free |
| AudioToolbox | NSSound | NSSound works but AudioToolbox is more reliable for alerts |

**Installation:**
No additional dependencies required - all system frameworks.

## Architecture Patterns

### Recommended Project Structure

```
ToEvent/
├── Services/
│   ├── NotificationService.swift      # NEW: UNUserNotificationCenter wrapper
│   ├── TravelTimeService.swift        # NEW: MapKit ETA calculation
│   └── MeetingURLParser.swift         # NEW: URL detection from text
├── Models/
│   └── Event.swift                    # EXTENDED: location, meetingURL, notes
├── Views/
│   ├── EventRowView.swift             # EXTENDED: action buttons
│   ├── EventDetailView.swift          # NEW: full event detail with actions
│   └── Settings/
│       └── NotificationSettingsView.swift  # NEW: notification preferences
├── Intent/
│   └── ToEventFocusFilter.swift       # NEW: FocusFilterIntent for Focus mode
└── Extensions/
    └── Event+Actions.swift            # NEW: computed properties for actions
```

### Pattern 1: Extended Event Model

**What:** Add location, URL, and notes fields to Event model
**When to use:** For all events, populated from EventKit or external APIs

```swift
// Source: Extend existing Event.swift
struct Event: Identifiable {
    // ... existing properties
    let location: String?
    let structuredLocation: CLLocation?  // For travel time
    let meetingURL: URL?                 // Detected or explicit
    let notes: String?                   // For URL parsing fallback
    let url: URL?                        // Event's explicit URL property
}
```

### Pattern 2: Notification Categories with Actions

**What:** UNNotificationCategory with snooze action buttons
**When to use:** For event reminder notifications

```swift
// Source: Apple UserNotifications documentation
let snooze3Action = UNNotificationAction(
    identifier: "SNOOZE_3",
    title: "3 min",
    options: []
)
let snooze5Action = UNNotificationAction(
    identifier: "SNOOZE_5",
    title: "5 min",
    options: []
)
let snooze10Action = UNNotificationAction(
    identifier: "SNOOZE_10",
    title: "10 min",
    options: []
)

let category = UNNotificationCategory(
    identifier: "EVENT_REMINDER",
    actions: [snooze3Action, snooze5Action, snooze10Action],
    intentIdentifiers: [],
    options: [.customDismissAction]
)
```

### Pattern 3: Meeting URL Detection

**What:** Regex-based detection of meeting URLs from text
**When to use:** Parsing event notes, descriptions, location fields

```swift
// Source: Community patterns for meeting URL detection
struct MeetingURLParser {
    static let patterns: [(name: String, regex: String)] = [
        ("Zoom", #"https?://([a-z0-9]+\.)?zoom(gov)?\.us/(j|my|w)/[a-zA-Z0-9]+"#),
        ("Google Meet", #"https?://meet\.google\.com/[a-z]+-[a-z]+-[a-z]+"#),
        ("Microsoft Teams", #"https?://teams\.microsoft\.com/l/meetup-join/[^\s]+"#),
        ("Webex", #"https?://([a-z0-9]+\.)?webex\.com/[^\s]+"#)
    ]

    static func findMeetingURL(in text: String) -> URL? {
        for (_, pattern) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range, in: text) {
                return URL(string: String(text[range]))
            }
        }
        return nil
    }
}
```

### Pattern 4: Travel Time Calculation

**What:** MKDirections.calculateETA for leave time
**When to use:** For events with geo-locations

```swift
// Source: Apple MapKit documentation
func calculateTravelTime(to destination: CLLocation) async throws -> TimeInterval {
    let request = MKDirections.Request()
    request.source = MKMapItem.forCurrentLocation()
    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
    request.transportType = .automobile

    let directions = MKDirections(request: request)
    let response = try await directions.calculateETA()
    return response.expectedTravelTime
}
```

### Anti-Patterns to Avoid

- **Using NSUserNotification:** Deprecated in macOS 11, will cause warnings and potential future breakage
- **Polling for Focus mode:** No API to query current Focus - use FocusFilterIntent instead
- **Hardcoding meeting URL patterns:** Use regex and make extensible for new services
- **Blocking UI for travel time:** Use async/await, show placeholder while calculating

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Notification scheduling | Manual timer | UNUserNotificationCenter | Handles app suspension, persistence |
| Snooze logic | Custom reschedule | UNNotificationCategory actions | System handles action dispatch |
| Travel time | Google Maps API | MKDirections.calculateETA() | Free, no API key, native |
| Opening Maps | Custom URL builder | MKMapItem.openInMaps() | Handles address parsing, directions |
| Sound playback | AVAudioPlayer | AudioServicesPlaySystemSound | Simpler for alerts, respects system volume |

**Key insight:** macOS notification and map APIs are comprehensive but have specific patterns. Using system APIs ensures compatibility and reduces maintenance.

## Common Pitfalls

### Pitfall 1: NSUserNotification Still Works (Until It Doesn't)

**What goes wrong:** App works on older macOS but fails/warns on 11+
**Why it happens:** NSUserNotification deprecated but still compiles
**How to avoid:** Use UNUserNotificationCenter exclusively, minimum target macOS 10.14+
**Warning signs:** Deprecation warnings in Xcode, notifications not appearing on Big Sur+

### Pitfall 2: Notification Permission Denied Silently

**What goes wrong:** Notifications scheduled but never appear
**Why it happens:** User denied permission or app not properly registered
**How to avoid:** Request authorization explicitly, check authorization status before scheduling
**Warning signs:** No error on `add()`, but notifications don't show

### Pitfall 3: Alert Style vs Banner Style

**What goes wrong:** Notification dismisses automatically instead of persisting
**Why it happens:** macOS defaults to banners, user must enable alerts in System Preferences
**How to avoid:** Guide user to enable alerts in System Preferences > Notifications, can't force programmatically
**Warning signs:** Notifications appear briefly then vanish

### Pitfall 4: Meeting URL in Wrong Field

**What goes wrong:** Meeting URL not detected for some events
**Why it happens:** Different calendar apps store URLs in different fields
**How to avoid:** Check multiple sources: explicit URL, location, notes/description, conferenceData
**Warning signs:** "Join" button missing for events that clearly have meeting links

### Pitfall 5: Travel Time Without Location Permission

**What goes wrong:** MKDirections fails with error
**Why it happens:** Need location permission for current location as source
**How to avoid:** Request when-in-use location permission, fallback to no travel time
**Warning signs:** `MKError.Code.directionsNotAvailable`

### Pitfall 6: Focus Mode Cannot Be Queried

**What goes wrong:** Cannot implement "show only work events in Work focus"
**Why it happens:** No API to query current Focus mode
**How to avoid:** Implement SetFocusFilterIntent - user configures filter per Focus
**Warning signs:** Searching for "get current focus mode" API returns no results

## API Reference

### Google Calendar Event - Meeting Fields

```json
{
  "hangoutLink": "https://meet.google.com/abc-defg-hij",
  "conferenceData": {
    "entryPoints": [
      {
        "entryPointType": "video",
        "uri": "https://meet.google.com/abc-defg-hij"
      }
    ],
    "conferenceSolution": {
      "key": { "type": "hangoutsMeet" }
    }
  },
  "location": "123 Main St, City, State"
}
```

### Microsoft Graph Event - Meeting Fields

```json
{
  "isOnlineMeeting": true,
  "onlineMeetingProvider": "teamsForBusiness",
  "onlineMeeting": {
    "joinUrl": "https://teams.microsoft.com/l/meetup-join/..."
  },
  "onlineMeetingUrl": null,  // DEPRECATED - use onlineMeeting.joinUrl
  "location": {
    "displayName": "Conference Room A"
  }
}
```

### EventKit EKEvent - Relevant Properties

| Property | Type | Notes |
|----------|------|-------|
| `location` | String? | Free-form location text |
| `structuredLocation` | EKStructuredLocation? | Has `geoLocation: CLLocation?` |
| `url` | URL? | Inherited from EKCalendarItem |
| `notes` | String? | Event notes/description |

## Code Examples

### UNUserNotificationCenter Setup

```swift
// Source: Apple UserNotifications documentation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    func setup() {
        center.delegate = self
        registerCategories()
    }

    func requestPermission() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        return try await center.requestAuthorization(options: options)
    }

    private func registerCategories() {
        let snooze3 = UNNotificationAction(identifier: "SNOOZE_3", title: "3 min", options: [])
        let snooze5 = UNNotificationAction(identifier: "SNOOZE_5", title: "5 min", options: [])
        let snooze10 = UNNotificationAction(identifier: "SNOOZE_10", title: "10 min", options: [])
        let join = UNNotificationAction(identifier: "JOIN_MEETING", title: "Join", options: [.foreground])

        let category = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [join, snooze3, snooze5, snooze10],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        center.setNotificationCategories([category])
    }

    func scheduleReminder(for event: Event, minutesBefore: Int) {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Starting in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        content.userInfo = ["eventId": event.id]

        let triggerDate = event.startDate.addingTimeInterval(-Double(minutesBefore * 60))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "event-\(event.id)", content: content, trigger: trigger)
        center.add(request)
    }

    // UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let eventId = response.notification.request.content.userInfo["eventId"] as? String

        switch response.actionIdentifier {
        case "SNOOZE_3":
            reschedule(eventId: eventId, minutes: 3)
        case "SNOOZE_5":
            reschedule(eventId: eventId, minutes: 5)
        case "SNOOZE_10":
            reschedule(eventId: eventId, minutes: 10)
        case "JOIN_MEETING":
            joinMeeting(eventId: eventId)
        default:
            break
        }
    }
}
```

### Opening Maps for Directions

```swift
// Source: Apple MapKit documentation
import MapKit

extension Event {
    func openInMaps() {
        guard let location = structuredLocation else {
            // Fallback: open Maps with address string search
            if let locationString = location,
               let encoded = locationString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: "maps://?daddr=\(encoded)") {
                NSWorkspace.shared.open(url)
            }
            return
        }

        let destination = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        destination.name = self.title
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}
```

### Conflict Detection

```swift
// Source: Standard interval overlap algorithm
extension Array where Element == Event {
    var conflicts: [(Event, Event)] {
        var result: [(Event, Event)] = []
        let timedEvents = filter { !$0.isAllDay }

        for i in 0..<timedEvents.count {
            for j in (i+1)..<timedEvents.count {
                let a = timedEvents[i]
                let b = timedEvents[j]
                if a.startDate < b.endDate && b.startDate < a.endDate {
                    result.append((a, b))
                }
            }
        }
        return result
    }
}
```

### Focus Filter Intent

```swift
// Source: Apple AppIntents documentation
import AppIntents

struct ToEventFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "ToEvent Focus Filter"
    static var description: IntentDescription? = "Filter which calendars appear during this Focus"

    @Parameter(title: "Show only calendars")
    var enabledCalendarNames: [String]?

    func perform() async throws -> some IntentResult {
        // Save filter state for AppState to read
        if let calendars = enabledCalendarNames {
            UserDefaults.standard.set(calendars, forKey: "focusFilterCalendars")
        } else {
            UserDefaults.standard.removeObject(forKey: "focusFilterCalendars")
        }
        return .result()
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| NSUserNotification | UNUserNotificationCenter | macOS 10.14 / deprecated 11 | Must use UNUserNotificationCenter |
| Polling Focus state | FocusFilterIntent | iOS 16 / macOS 13 | Apps receive Focus changes via Intent |
| Manual URL parsing | hangoutLink/conferenceData | Google API 2018 | More reliable meeting URL extraction |
| onlineMeetingUrl | onlineMeeting.joinUrl | Microsoft deprecation | Use joinUrl for Teams links |

**Deprecated/outdated:**
- **NSUserNotification:** Deprecated macOS 11, use UNUserNotificationCenter
- **onlineMeetingUrl (Microsoft):** Deprecated, use onlineMeeting.joinUrl
- **Focus mode detection via plist:** Unreliable, use FocusFilterIntent

## Open Questions

Things that couldn't be fully resolved:

1. **Notification persistence (Alert vs Banner)**
   - What we know: App cannot force Alert style; user must configure in System Preferences
   - What's unclear: Whether to prompt user to change setting or accept banner behavior
   - Recommendation: Check authorization status and show settings guidance if needed

2. **Focus mode without user configuration**
   - What we know: Apps cannot query current Focus mode, only receive via FocusFilterIntent
   - What's unclear: How to handle if user never configures Focus filter
   - Recommendation: Default to showing all events, only filter when user configures Focus filter

3. **Travel time accuracy without location permission**
   - What we know: MKDirections needs source location
   - What's unclear: Whether to require location permission or use fallback
   - Recommendation: Request when-in-use permission on first travel time request, graceful degradation

4. **Quick-add event complexity**
   - What we know: Can create EKEvent programmatically
   - What's unclear: Minimum viable UI for quick-add vs opening Calendar.app
   - Recommendation: Start with opening Calendar.app new event, consider in-app later

## Sources

### Primary (HIGH confidence)
- [Apple UNUserNotificationCenter](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter) - Notification scheduling and actions
- [Apple MKDirections](https://developer.apple.com/documentation/mapkit/mkdirections) - Travel time ETA calculation
- [Google Calendar API Events](https://developers.google.com/calendar/api/v3/reference/events) - hangoutLink, conferenceData fields
- [Microsoft Graph Event](https://learn.microsoft.com/en-us/graph/api/resources/event) - onlineMeeting, location fields
- [Apple Focus Filters](https://developer.apple.com/documentation/appintents/focus) - SetFocusFilterIntent pattern

### Secondary (MEDIUM confidence)
- [Hacking with Swift Notifications](https://www.hackingwithswift.com/read/21/2) - UNNotificationRequest patterns
- [regex101 Zoom patterns](https://regex101.com/library/zWR4lJ) - Meeting URL regex
- [Apple Map Links](https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/MapLinks/MapLinks.html) - URL scheme for directions

### Tertiary (LOW confidence)
- WebSearch results on Focus mode detection - Conflicting information, official docs preferred
- WebSearch results on notification persistence - User-configurable, limited app control

## Metadata

**Confidence breakdown:**
- Notifications: HIGH - UNUserNotificationCenter well-documented
- Travel time: HIGH - MKDirections API straightforward
- Meeting URL detection: MEDIUM - Multiple sources, regex patterns vary
- Focus mode: MEDIUM - API exists but limited query capability
- Conflict detection: HIGH - Simple interval overlap algorithm

**Research date:** 2026-01-24
**Valid until:** 2026-02-24 (30 days - stable system APIs)
