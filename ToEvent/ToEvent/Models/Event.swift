import EventKit
import CoreGraphics
import Foundation

struct Event: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarColor: CGColor
    let calendarID: String
    let calendarTitle: String
    let source: CalendarProviderType
    let accountId: String?
    let location: String?
    let meetingURL: URL?
    let notes: String?
    let url: URL?

    init(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        calendarColor: CGColor,
        calendarID: String,
        calendarTitle: String,
        source: CalendarProviderType = .local,
        accountId: String? = nil,
        location: String? = nil,
        meetingURL: URL? = nil,
        notes: String? = nil,
        url: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.calendarColor = calendarColor
        self.calendarID = calendarID
        self.calendarTitle = calendarTitle
        self.source = source
        self.accountId = accountId
        self.location = location
        self.meetingURL = meetingURL
        self.notes = notes
        self.url = url
    }

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? "Untitled Event"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.calendarColor = ekEvent.calendar?.cgColor ?? CGColor(gray: 0.5, alpha: 1.0)
        self.calendarID = ekEvent.calendar?.calendarIdentifier ?? ""
        self.calendarTitle = ekEvent.calendar?.title ?? "Unknown"
        self.source = .local
        self.accountId = nil
        self.location = ekEvent.location
        self.notes = ekEvent.notes
        self.url = ekEvent.url
        self.meetingURL = MeetingURLParser.findMeetingURL(
            url: ekEvent.url,
            location: ekEvent.location,
            notes: ekEvent.notes
        )
    }
}
