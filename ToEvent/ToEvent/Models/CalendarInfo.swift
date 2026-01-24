import EventKit
import CoreGraphics

struct CalendarInfo: Identifiable {
    let id: String
    let title: String
    let color: CGColor
    let source: String
    let providerType: CalendarProviderType
    let accountId: String?

    init(
        id: String,
        title: String,
        color: CGColor,
        source: String,
        providerType: CalendarProviderType = .local,
        accountId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.color = color
        self.source = source
        self.providerType = providerType
        self.accountId = accountId
    }

    init(from ekCalendar: EKCalendar) {
        self.id = ekCalendar.calendarIdentifier
        self.title = ekCalendar.title
        self.color = ekCalendar.cgColor ?? CGColor(gray: 0.5, alpha: 1.0)
        self.source = ekCalendar.source?.title ?? "Unknown"
        self.providerType = .local
        self.accountId = nil
    }
}
