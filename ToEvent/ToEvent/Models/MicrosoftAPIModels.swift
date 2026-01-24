import CoreGraphics
import Foundation

// MARK: - Microsoft Graph API Response Models

struct MicrosoftCalendarsResponse: Codable {
    let value: [MicrosoftCalendar]
}

struct MicrosoftCalendar: Codable {
    let id: String
    let name: String
    let color: String?
    let isDefaultCalendar: Bool?

    func toCalendarInfo(accountId: String) -> CalendarInfo {
        CalendarInfo(
            id: id,
            title: name,
            color: microsoftColorToCGColor(color),
            source: "Microsoft",
            providerType: .outlook,
            accountId: accountId
        )
    }
}

struct MicrosoftEventsResponse: Codable {
    let value: [MicrosoftEvent]?
}

struct MicrosoftEvent: Codable {
    let id: String
    let subject: String?
    let start: MicrosoftDateTime
    let end: MicrosoftDateTime
    let isAllDay: Bool?
    let isCancelled: Bool?
    let location: MicrosoftLocation?
    let body: MicrosoftBody?
    let onlineMeeting: MicrosoftOnlineMeeting?
    let webLink: String?

    func toEvent(
        calendarId: String,
        calendarTitle: String,
        calendarColor: CGColor,
        accountId: String
    ) -> Event {
        let locationText = location?.displayName

        let meetingURL: URL?
        if let joinUrl = onlineMeeting?.joinUrl {
            meetingURL = URL(string: joinUrl)
        } else {
            meetingURL = MeetingURLParser.findMeetingURL(
                url: nil,
                location: locationText,
                notes: body?.content
            )
        }

        return Event(
            id: id,
            title: subject ?? "Untitled Event",
            startDate: start.toDate() ?? Date(),
            endDate: end.toDate() ?? Date(),
            isAllDay: isAllDay ?? false,
            calendarColor: calendarColor,
            calendarID: calendarId,
            calendarTitle: calendarTitle,
            source: .outlook,
            accountId: accountId,
            location: locationText,
            meetingURL: meetingURL,
            notes: body?.content,
            url: webLink.flatMap { URL(string: $0) }
        )
    }
}

struct MicrosoftLocation: Codable {
    let displayName: String?
}

struct MicrosoftBody: Codable {
    let content: String?
    let contentType: String?
}

struct MicrosoftOnlineMeeting: Codable {
    let joinUrl: String?
}

struct MicrosoftDateTime: Codable {
    let dateTime: String
    let timeZone: String

    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        if let tz = TimeZone(identifier: timeZone) {
            formatter.timeZone = tz
        } else if let tz = windowsTimeZoneToIdentifier(timeZone) {
            formatter.timeZone = tz
        } else {
            formatter.timeZone = TimeZone.current
        }

        if let date = formatter.date(from: dateTime) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: dateTime)
    }
}

// MARK: - Color Mapping

private func microsoftColorToCGColor(_ colorName: String?) -> CGColor {
    guard let colorName = colorName?.lowercased() else {
        return CGColor(gray: 0.5, alpha: 1.0)
    }

    switch colorName {
    case "lightblue":
        return CGColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
    case "lightgreen":
        return CGColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 1.0)
    case "lightorange":
        return CGColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    case "lightgray", "lightgrey":
        return CGColor(gray: 0.7, alpha: 1.0)
    case "lightyellow":
        return CGColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1.0)
    case "lightteal":
        return CGColor(red: 0.4, green: 0.8, blue: 0.8, alpha: 1.0)
    case "lightpink":
        return CGColor(red: 1.0, green: 0.6, blue: 0.7, alpha: 1.0)
    case "lightbrown":
        return CGColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
    case "lightred":
        return CGColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
    case "maxcolor":
        return CGColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0)
    case "auto":
        return CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0)
    default:
        return CGColor(gray: 0.5, alpha: 1.0)
    }
}

// MARK: - Windows Timezone Mapping

private func windowsTimeZoneToIdentifier(_ windowsName: String) -> TimeZone? {
    let mapping: [String: String] = [
        "Pacific Standard Time": "America/Los_Angeles",
        "Mountain Standard Time": "America/Denver",
        "Central Standard Time": "America/Chicago",
        "Eastern Standard Time": "America/New_York",
        "GMT Standard Time": "Europe/London",
        "Central European Standard Time": "Europe/Berlin",
        "W. Europe Standard Time": "Europe/Berlin",
        "Romance Standard Time": "Europe/Paris",
        "UTC": "UTC",
        "Coordinated Universal Time": "UTC",
        "Tokyo Standard Time": "Asia/Tokyo",
        "China Standard Time": "Asia/Shanghai",
        "India Standard Time": "Asia/Kolkata",
        "AUS Eastern Standard Time": "Australia/Sydney"
    ]

    if let identifier = mapping[windowsName] {
        return TimeZone(identifier: identifier)
    }
    return nil
}
