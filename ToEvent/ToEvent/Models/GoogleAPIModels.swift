import CoreGraphics
import AppKit

// MARK: - Calendar List Response

struct GoogleCalendarsResponse: Codable {
    let items: [GoogleCalendar]
}

struct GoogleCalendar: Codable {
    let id: String
    let summary: String
    let backgroundColor: String?
    let primary: Bool?

    func toCalendarInfo(accountId: String) -> CalendarInfo {
        CalendarInfo(
            id: id,
            title: summary,
            color: parseHexColor(backgroundColor) ?? CGColor(gray: 0.5, alpha: 1.0),
            source: "Google",
            providerType: .google,
            accountId: accountId
        )
    }
}

// MARK: - Events Response

struct GoogleEventsResponse: Codable {
    let items: [GoogleEvent]?
}

struct GoogleEvent: Codable {
    let id: String
    let summary: String?
    let start: GoogleEventDateTime
    let end: GoogleEventDateTime
    let status: String?
    let location: String?
    let description: String?
    let hangoutLink: String?
    let htmlLink: String?

    func toEvent(
        calendarId: String,
        calendarTitle: String,
        calendarColor: CGColor,
        accountId: String
    ) -> Event? {
        guard status != "cancelled" else { return nil }

        let (startDate, isAllDay) = start.toDate()
        let (endDate, _) = end.toDate()

        guard let startDate = startDate, let endDate = endDate else {
            return nil
        }

        let meetingURL: URL?
        if let hangout = hangoutLink {
            meetingURL = URL(string: hangout)
        } else {
            meetingURL = MeetingURLParser.findMeetingURL(
                url: nil,
                location: location,
                notes: description
            )
        }

        return Event(
            id: id,
            title: summary ?? "Untitled Event",
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            calendarColor: calendarColor,
            calendarID: calendarId,
            calendarTitle: calendarTitle,
            source: .google,
            accountId: accountId,
            location: location,
            meetingURL: meetingURL,
            notes: description,
            url: htmlLink.flatMap { URL(string: $0) }
        )
    }
}

struct GoogleEventDateTime: Codable {
    let dateTime: String?
    let date: String?
    let timeZone: String?

    func toDate() -> (Date?, Bool) {
        if let dateTimeString = dateTime {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateTimeString) {
                return (date, false)
            }
            formatter.formatOptions = [.withInternetDateTime]
            return (formatter.date(from: dateTimeString), false)
        }

        if let dateString = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone.current
            return (formatter.date(from: dateString), true)
        }

        return (nil, false)
    }
}

// MARK: - Hex Color Parsing

private func parseHexColor(_ hex: String?) -> CGColor? {
    guard let hex = hex else { return nil }

    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if hexString.hasPrefix("#") {
        hexString.removeFirst()
    }

    guard hexString.count == 6 else { return nil }

    var rgbValue: UInt64 = 0
    guard Scanner(string: hexString).scanHexInt64(&rgbValue) else { return nil }

    let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

    return CGColor(red: red, green: green, blue: blue, alpha: 1.0)
}
