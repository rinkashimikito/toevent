import SwiftUI
import EventKit
import Combine
import AppKit

enum TimeDisplayFormat: String, CaseIterable, Identifiable {
    case countdown = "countdown"
    case absolute = "absolute"
    case both = "both"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .countdown: return "Countdown (5m 30s)"
        case .absolute: return "Absolute (2:30 PM)"
        case .both: return "Both (5m 30s - 2:30 PM)"
        }
    }
}

final class AppState: ObservableObject {
    @Published var hasCompletedIntro: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedIntro, forKey: Keys.hasCompletedIntro)
        }
    }

    var authorizationStatus: EKAuthorizationStatus {
        CalendarService.shared.authorizationStatus()
    }

    @Published private(set) var events: [Event] = []
    @Published private(set) var nextEvent: Event? {
        didSet { updateMenuBarTitle() }
    }
    @Published var currentTime = Date() {
        didSet { updateMenuBarTitle() }
    }

    var filteredEvents: [Event] {
        if UserDefaults.standard.bool(forKey: "focusHideAllEvents") {
            return []
        }

        if let focusCalendars = UserDefaults.standard.stringArray(forKey: "focusFilterCalendars"),
           !focusCalendars.isEmpty {
            return events.filter { event in
                focusCalendars.contains(event.calendarTitle)
            }
        }

        return events
    }

    var allDayEvents: [Event] {
        filteredEvents.filter { $0.isAllDay }
    }

    var timedEvents: [Event] {
        filteredEvents.filter { !$0.isAllDay }
    }

    var conflictingEventIDs: Set<String> {
        events.conflictingEventIDs
    }

    func hasConflict(_ event: Event) -> Bool {
        conflictingEventIDs.contains(event.id)
    }

    @Published private(set) var menuBarTitle: String = "ToEvent"
    @Published private(set) var isScreenLocked = false

    @Published var timeDisplayFormat: TimeDisplayFormat {
        didSet {
            UserDefaults.standard.set(timeDisplayFormat.rawValue, forKey: Keys.timeDisplayFormat)
            updateMenuBarTitle()
        }
    }

    @Published var useNaturalLanguage: Bool {
        didSet {
            UserDefaults.standard.set(useNaturalLanguage, forKey: Keys.useNaturalLanguage)
            updateMenuBarTitle()
        }
    }

    @Published var privacyMode: Bool {
        didSet {
            UserDefaults.standard.set(privacyMode, forKey: Keys.privacyMode)
            updateMenuBarTitle()
        }
    }

    @Published var hideAllDayEvents: Bool = true {
        didSet {
            UserDefaults.standard.set(hideAllDayEvents, forKey: Keys.hideAllDayEvents)
            refreshEvents()
        }
    }

    @Published var showMenuBarIcon: Bool = true {
        didSet {
            UserDefaults.standard.set(showMenuBarIcon, forKey: Keys.showMenuBarIcon)
        }
    }

    @Published var menuBarTitleMaxLength: Int = 20 {
        didSet {
            UserDefaults.standard.set(menuBarTitleMaxLength, forKey: Keys.menuBarTitleMaxLength)
            updateMenuBarTitle()
        }
    }

    @Published var urgencyThresholds: UrgencyThresholds {
        didSet {
            UserDefaults.standard.set(urgencyThresholds.imminent, forKey: Keys.urgencyImminent)
            UserDefaults.standard.set(urgencyThresholds.soon, forKey: Keys.urgencySoon)
            UserDefaults.standard.set(urgencyThresholds.approaching, forKey: Keys.urgencyApproaching)
        }
    }

    var urgencyLevel: UrgencyLevel {
        guard let event = nextEvent else { return .normal }
        let remaining = event.startDate.timeIntervalSince(Date())
        return UrgencyLevel.from(secondsRemaining: remaining, thresholds: urgencyThresholds)
    }

    private func updateMenuBarTitle() {
        guard let event = nextEvent else {
            menuBarTitle = "ToEvent"
            return
        }

        let displayTitle: String
        if privacyMode {
            displayTitle = "Event"
        } else if menuBarTitleMaxLength == 0 {
            displayTitle = event.title
        } else {
            displayTitle = event.title.count > menuBarTitleMaxLength
                ? String(event.title.prefix(menuBarTitleMaxLength)) + "..."
                : event.title
        }

        if event.isAllDay {
            menuBarTitle = "\(displayTitle) today"
        } else {
            let timeString = formatTimeForMenuBar(until: event.startDate, from: currentTime)
            if useNaturalLanguage && timeDisplayFormat != .absolute {
                menuBarTitle = "\(displayTitle) \(timeString)"
            } else {
                menuBarTitle = "\(displayTitle) in \(timeString)"
            }
        }
    }

    private func formatTimeForMenuBar(until date: Date, from now: Date) -> String {
        switch timeDisplayFormat {
        case .countdown:
            return useNaturalLanguage
                ? DateFormatters.formatNaturalLanguage(until: date, from: now)
                : DateFormatters.formatHybridCountdown(until: date, from: now)
        case .absolute:
            return DateFormatters.formatAbsoluteTime(date)
        case .both:
            let countdown = useNaturalLanguage
                ? DateFormatters.formatNaturalLanguage(until: date, from: now)
                : DateFormatters.formatHybridCountdown(until: date, from: now)
            let absolute = DateFormatters.formatAbsoluteTime(date)
            return "\(countdown) (\(absolute))"
        }
    }

    @Published var enabledCalendarIDs: Set<String>? {
        didSet {
            if let ids = enabledCalendarIDs {
                UserDefaults.standard.set(Array(ids), forKey: Keys.enabledCalendarIDs)
            } else {
                UserDefaults.standard.removeObject(forKey: Keys.enabledCalendarIDs)
            }
        }
    }

    @Published var lookahead: TimeInterval {
        didSet {
            UserDefaults.standard.set(lookahead, forKey: Keys.lookahead)
        }
    }

    @Published var calendarPriority: [String] {
        didSet {
            UserDefaults.standard.set(calendarPriority, forKey: Keys.calendarPriority)
        }
    }

    @Published var fetchInterval: TimeInterval {
        didSet {
            UserDefaults.standard.set(fetchInterval, forKey: Keys.fetchInterval)
            CalendarService.shared.updateFetchInterval(fetchInterval)
        }
    }

    @Published var maxEventsToShow: Int {
        didSet {
            UserDefaults.standard.set(maxEventsToShow, forKey: Keys.maxEventsToShow)
        }
    }

    enum NotificationSoundOption: String, CaseIterable, Identifiable {
        case `default` = "default"
        case subtle = "subtle"
        case urgent = "urgent"
        case none = "none"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .default: return "Default"
            case .subtle: return "Subtle"
            case .urgent: return "Urgent"
            case .none: return "None"
            }
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
            if notificationsEnabled {
                scheduleNotificationsForEvents()
            } else {
                NotificationService.shared.cancelAllReminders()
            }
        }
    }

    @Published var reminderMinutes: Int {
        didSet {
            UserDefaults.standard.set(reminderMinutes, forKey: Keys.reminderMinutes)
            if notificationsEnabled {
                scheduleNotificationsForEvents()
            }
        }
    }

    @Published var notificationSound: NotificationSoundOption {
        didSet {
            UserDefaults.standard.set(notificationSound.rawValue, forKey: Keys.notificationSound)
            if notificationsEnabled {
                scheduleNotificationsForEvents()
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?

    private enum Keys {
        static let hasCompletedIntro = "hasCompletedIntro"
        static let enabledCalendarIDs = "enabledCalendarIDs"
        static let lookahead = "lookahead"
        static let calendarPriority = "calendarPriority"
        static let timeDisplayFormat = "timeDisplayFormat"
        static let useNaturalLanguage = "useNaturalLanguage"
        static let privacyMode = "privacyMode"
        static let hideAllDayEvents = "hideAllDayEvents"
        static let showMenuBarIcon = "showMenuBarIcon"
        static let menuBarTitleMaxLength = "menuBarTitleMaxLength"
        static let urgencyImminent = "urgencyImminent"
        static let urgencySoon = "urgencySoon"
        static let urgencyApproaching = "urgencyApproaching"
        static let fetchInterval = "fetchInterval"
        static let maxEventsToShow = "maxEventsToShow"
        static let notificationsEnabled = "notificationsEnabled"
        static let reminderMinutes = "reminderMinutes"
        static let notificationSound = "notificationSound"
    }

    init() {
        self.hasCompletedIntro = UserDefaults.standard.bool(forKey: Keys.hasCompletedIntro)

        if let ids = UserDefaults.standard.array(forKey: Keys.enabledCalendarIDs) as? [String] {
            self.enabledCalendarIDs = Set(ids)
        } else {
            self.enabledCalendarIDs = nil
        }

        let storedLookahead = UserDefaults.standard.double(forKey: Keys.lookahead)
        self.lookahead = storedLookahead > 0 ? storedLookahead : 86400

        self.calendarPriority = UserDefaults.standard.stringArray(forKey: Keys.calendarPriority) ?? []

        if let formatRaw = UserDefaults.standard.string(forKey: Keys.timeDisplayFormat),
           let format = TimeDisplayFormat(rawValue: formatRaw) {
            self.timeDisplayFormat = format
        } else {
            self.timeDisplayFormat = .countdown
        }
        self.useNaturalLanguage = UserDefaults.standard.bool(forKey: Keys.useNaturalLanguage)
        self.privacyMode = UserDefaults.standard.bool(forKey: Keys.privacyMode)

        if UserDefaults.standard.object(forKey: Keys.hideAllDayEvents) != nil {
            self.hideAllDayEvents = UserDefaults.standard.bool(forKey: Keys.hideAllDayEvents)
        }

        if UserDefaults.standard.object(forKey: Keys.showMenuBarIcon) != nil {
            self.showMenuBarIcon = UserDefaults.standard.bool(forKey: Keys.showMenuBarIcon)
        }

        let storedMaxLength = UserDefaults.standard.integer(forKey: Keys.menuBarTitleMaxLength)
        if storedMaxLength > 0 {
            self.menuBarTitleMaxLength = storedMaxLength
        }

        let imminent = UserDefaults.standard.double(forKey: Keys.urgencyImminent)
        let soon = UserDefaults.standard.double(forKey: Keys.urgencySoon)
        let approaching = UserDefaults.standard.double(forKey: Keys.urgencyApproaching)
        if imminent > 0 && soon > 0 && approaching > 0 {
            self.urgencyThresholds = UrgencyThresholds(
                imminent: imminent,
                soon: soon,
                approaching: approaching
            )
        } else {
            self.urgencyThresholds = .default
        }

        let storedFetchInterval = UserDefaults.standard.double(forKey: Keys.fetchInterval)
        self.fetchInterval = storedFetchInterval > 0 ? storedFetchInterval : 900

        let storedMaxEvents = UserDefaults.standard.integer(forKey: Keys.maxEventsToShow)
        self.maxEventsToShow = storedMaxEvents > 0 ? storedMaxEvents : 10

        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)

        let storedReminderMinutes = UserDefaults.standard.integer(forKey: Keys.reminderMinutes)
        self.reminderMinutes = storedReminderMinutes > 0 ? storedReminderMinutes : 5

        if let soundRaw = UserDefaults.standard.string(forKey: Keys.notificationSound),
           let sound = NotificationSoundOption(rawValue: soundRaw) {
            self.notificationSound = sound
        } else {
            self.notificationSound = .default
        }

        observeCalendarChanges()
        observeScreenLock()
        observeFocusFilterChanges()

        if hasCompletedIntro {
            // Delay initial refresh to allow EventKit store to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshEvents()
                self?.startCountdownTimer()
                CalendarService.shared.startBackgroundFetch(interval: self?.fetchInterval ?? 300)
            }
        }
    }

    deinit {
        stopCountdownTimer()
    }

    private func observeScreenLock() {
        SystemStateService.shared.$isScreenLocked
            .receive(on: DispatchQueue.main)
            .sink { [weak self] locked in
                self?.isScreenLocked = locked
                if locked {
                    self?.stopCountdownTimer()
                } else {
                    self?.startCountdownTimer()
                }
            }
            .store(in: &cancellables)

        SystemStateService.shared.didWake
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.currentTime = Date()
                self?.refreshEvents()
            }
            .store(in: &cancellables)
    }

    private func observeFocusFilterChanges() {
        NotificationCenter.default.addObserver(
            forName: .focusFilterChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    private func startCountdownTimer() {
        stopCountdownTimer()
        let interval = countdownInterval
        countdownTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tickCountdown()
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func tickCountdown() {
        currentTime = Date()

        // Only refresh when ongoing event ends, not when it starts
        if let event = nextEvent, event.endDate <= currentTime {
            refreshEvents()
        }

        // Reschedule if interval needs to change
        let newInterval = countdownInterval
        if let timer = countdownTimer, timer.timeInterval != newInterval {
            startCountdownTimer()
        }
    }

    private var countdownInterval: TimeInterval {
        guard let event = nextEvent, !event.isAllDay else { return 60 }
        let now = Date()

        // Event is ongoing - update every 60s (just for time display)
        if event.startDate <= now && now < event.endDate {
            return 60
        }

        // Event is upcoming - update based on how close
        let remaining = event.startDate.timeIntervalSince(now)
        return remaining <= 300 ? 1 : 60
    }

    private func observeCalendarChanges() {
        CalendarService.shared.$lastRefresh
            .dropFirst()
            .sink { [weak self] _ in
                self?.refreshEvents()
            }
            .store(in: &cancellables)
    }

    var accountsNeedingReauth: [CalendarAccount] {
        CalendarProviderManager.shared.expiredAccounts
    }

    func refreshEvents() {
        Task {
            let now = Date()
            let endDate = now.addingTimeInterval(lookahead)
            let fetchedEvents = await CalendarProviderManager.shared.fetchAllEvents(
                from: now,
                to: endDate,
                enabledCalendarIDs: enabledCalendarIDs
            )

            let sortedEvents = fetchedEvents.sorted { a, b in
                if a.startDate != b.startDate {
                    return a.startDate < b.startDate
                }
                let aIndex = calendarPriority.firstIndex(of: a.calendarID) ?? Int.max
                let bIndex = calendarPriority.firstIndex(of: b.calendarID) ?? Int.max
                return aIndex < bIndex
            }

            await MainActor.run {
                self.events = sortedEvents
                if self.hideAllDayEvents {
                    self.nextEvent = sortedEvents.first { !$0.isAllDay }
                } else {
                    self.nextEvent = sortedEvents.first
                }
                if self.notificationsEnabled {
                    self.scheduleNotificationsForEvents()
                }
            }
        }
    }

    private func scheduleNotificationsForEvents() {
        guard notificationsEnabled else { return }

        NotificationService.shared.cancelAllReminders()

        let upcomingEvents = events.filter { event in
            !event.isAllDay &&
            event.startDate > Date() &&
            event.startDate < Date().addingTimeInterval(86400)
        }

        let serviceSoundOption: ToEvent.NotificationSoundOption
        switch notificationSound {
        case .default: serviceSoundOption = .default
        case .subtle: serviceSoundOption = .subtle
        case .urgent: serviceSoundOption = .urgent
        case .none: serviceSoundOption = .none
        }

        Task {
            for event in upcomingEvents {
                try? await NotificationService.shared.scheduleReminder(
                    for: event,
                    minutesBefore: reminderMinutes,
                    soundOption: serviceSoundOption
                )
            }
        }
    }

    func initializeCalendarPriority(with calendars: [CalendarInfo]) {
        let existingIDs = Set(calendarPriority)
        let newCalendars = calendars.filter { !existingIDs.contains($0.id) }
        if !newCalendars.isEmpty {
            calendarPriority.append(contentsOf: newCalendars.map { $0.id })
        }
    }
}
