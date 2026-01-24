import EventKit
import Combine

final class CalendarService: ObservableObject, @unchecked Sendable {
    static let shared = CalendarService()

    private let store = EKEventStore()
    private var cancellables = Set<AnyCancellable>()
    private var backgroundActivity: NSBackgroundActivityScheduler?
    private var currentFetchInterval: TimeInterval = 300

    @Published var lastRefresh = Date()

    private init() {
        observeChanges()
    }

    func updateFetchInterval(_ interval: TimeInterval) {
        guard interval != currentFetchInterval else { return }
        currentFetchInterval = interval
        restartBackgroundFetch()
    }

    func startBackgroundFetch(interval: TimeInterval) {
        currentFetchInterval = interval
        restartBackgroundFetch()
    }

    private func restartBackgroundFetch() {
        stopBackgroundFetch()

        backgroundActivity = NSBackgroundActivityScheduler(identifier: "com.toevent.calendarFetch")
        backgroundActivity?.repeats = true
        backgroundActivity?.interval = currentFetchInterval
        backgroundActivity?.tolerance = currentFetchInterval * 0.25
        backgroundActivity?.qualityOfService = .utility

        backgroundActivity?.schedule { [weak self] completion in
            guard let self = self else {
                completion(.finished)
                return
            }

            if self.backgroundActivity?.shouldDefer == true {
                completion(.deferred)
                return
            }

            DispatchQueue.main.async {
                self.lastRefresh = Date()
                completion(.finished)
            }
        }
    }

    func stopBackgroundFetch() {
        backgroundActivity?.invalidate()
        backgroundActivity = nil
    }

    private func observeChanges() {
        NotificationCenter.default.publisher(for: .EKEventStoreChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lastRefresh = Date()
            }
            .store(in: &cancellables)
    }

    func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        let status = authorizationStatus()

        switch status {
        case .notDetermined:
            let granted = await requestAccessFromSystem()
            if granted {
                store.reset()
            }
            return granted
        case .fullAccess, .authorized:
            return true
        case .denied, .restricted, .writeOnly:
            return false
        @unknown default:
            return false
        }
    }

    private func requestAccessFromSystem() async -> Bool {
        if #available(macOS 14.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func fetchUpcomingEvents(from calendarIDs: [String]?, lookahead: TimeInterval, priority: [String] = []) -> [Event] {
        let now = Date()
        let endDate = now.addingTimeInterval(lookahead)

        let calendars: [EKCalendar]?
        if let calendarIDs = calendarIDs {
            calendars = calendarIDs.compactMap { id in
                store.calendar(withIdentifier: id)
            }
        } else {
            calendars = nil
        }

        let predicate = store.predicateForEvents(
            withStart: now,
            end: endDate,
            calendars: calendars
        )

        let ekEvents = store.events(matching: predicate)

        return ekEvents
            .sorted { a, b in
                if a.startDate != b.startDate {
                    return a.startDate < b.startDate
                }
                let aIndex = priority.firstIndex(of: a.calendar?.calendarIdentifier ?? "") ?? Int.max
                let bIndex = priority.firstIndex(of: b.calendar?.calendarIdentifier ?? "") ?? Int.max
                return aIndex < bIndex
            }
            .map { Event(from: $0) }
    }

    func getCalendars() -> [CalendarInfo] {
        store.calendars(for: .event)
            .map { CalendarInfo(from: $0) }
    }
}
