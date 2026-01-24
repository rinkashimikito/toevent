import AppIntents

@available(macOS 13.0, *)
struct ToEventFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "ToEvent Focus Filter"
    static var description: IntentDescription? = IntentDescription(
        "Filter which calendars appear in ToEvent during this Focus"
    )

    @Parameter(title: "Show only calendars")
    var enabledCalendarNames: [String]?

    @Parameter(title: "Hide all events")
    var hideAllEvents: Bool?

    var displayRepresentation: DisplayRepresentation {
        if hideAllEvents == true {
            return DisplayRepresentation(stringLiteral: "Hide all events")
        } else if let calendars = enabledCalendarNames, !calendars.isEmpty {
            let names = calendars.joined(separator: ", ")
            return DisplayRepresentation(stringLiteral: "Show: \(names)")
        } else {
            return DisplayRepresentation(stringLiteral: "Show all calendars")
        }
    }

    func perform() async throws -> some IntentResult {
        if hideAllEvents == true {
            UserDefaults.standard.set(true, forKey: "focusHideAllEvents")
            UserDefaults.standard.removeObject(forKey: "focusFilterCalendars")
        } else if let calendars = enabledCalendarNames, !calendars.isEmpty {
            UserDefaults.standard.set(calendars, forKey: "focusFilterCalendars")
            UserDefaults.standard.set(false, forKey: "focusHideAllEvents")
        } else {
            UserDefaults.standard.removeObject(forKey: "focusFilterCalendars")
            UserDefaults.standard.set(false, forKey: "focusHideAllEvents")
        }

        NotificationCenter.default.post(name: .focusFilterChanged, object: nil)

        return .result()
    }
}

extension Notification.Name {
    static let focusFilterChanged = Notification.Name("focusFilterChanged")
}
