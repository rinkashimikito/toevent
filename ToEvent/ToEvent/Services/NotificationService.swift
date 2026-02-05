import Foundation
import UserNotifications
import Combine
import AppKit

enum NotificationError: Error {
    case permissionDenied
    case schedulingFailed(Error)
}

/// Sound options for notifications - matches AppState.NotificationSoundOption
enum NotificationSoundOption: String {
    case `default` = "default"
    case subtle = "subtle"
    case urgent = "urgent"
    case none = "none"

    var unNotificationSound: UNNotificationSound? {
        switch self {
        case .default:
            return .default
        case .subtle:
            // Use a quieter system sound
            return UNNotificationSound(named: UNNotificationSoundName("Blow"))
        case .urgent:
            // Use a more attention-grabbing sound
            return UNNotificationSound(named: UNNotificationSoundName("Glass"))
        case .none:
            return nil
        }
    }
}

final class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    @Published private(set) var isAuthorized = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // Category identifiers
    static let eventReminderCategory = "EVENT_REMINDER"

    // Action identifiers
    static let snooze3Action = "SNOOZE_3"
    static let snooze5Action = "SNOOZE_5"
    static let snooze10Action = "SNOOZE_10"
    static let joinMeetingAction = "JOIN_MEETING"
    static let dismissAction = UNNotificationDismissActionIdentifier

    private override init() {
        super.init()
    }

    // MARK: - Setup

    func setup() {
        center.delegate = self
        registerCategories()
        Task {
            await checkAuthorizationStatus()
        }
    }

    private func registerCategories() {
        let snooze3 = UNNotificationAction(
            identifier: Self.snooze3Action,
            title: "3 min",
            options: []
        )
        let snooze5 = UNNotificationAction(
            identifier: Self.snooze5Action,
            title: "5 min",
            options: []
        )
        let snooze10 = UNNotificationAction(
            identifier: Self.snooze10Action,
            title: "10 min",
            options: []
        )
        let join = UNNotificationAction(
            identifier: Self.joinMeetingAction,
            title: "Join Meeting",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: Self.eventReminderCategory,
            actions: [join, snooze3, snooze5, snooze10],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        center.setNotificationCategories([category])
    }

    // MARK: - Authorization

    @MainActor
    private func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestPermission() async throws -> Bool {
        // Check current status first
        let settings = await center.notificationSettings()

        // If already denied, open System Settings (dialog won't show again)
        if settings.authorizationStatus == .denied {
            await MainActor.run {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                    NSWorkspace.shared.open(url)
                }
            }
            return false
        }

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)

        // Refresh status from system
        await checkAuthorizationStatus()

        return granted
    }

    // MARK: - Scheduling

    /// Schedule a reminder for an event
    /// - Parameters:
    ///   - event: The event to remind about
    ///   - minutesBefore: How many minutes before the event to trigger
    ///   - soundOption: The sound preference (default, subtle, urgent, none)
    func scheduleReminder(
        for event: Event,
        minutesBefore: Int,
        soundOption: NotificationSoundOption = .default
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.permissionDenied
        }

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "Starting in \(minutesBefore) minute\(minutesBefore == 1 ? "" : "s")"
        content.sound = soundOption.unNotificationSound
        content.categoryIdentifier = Self.eventReminderCategory
        content.userInfo = [
            "eventId": event.id,
            "meetingURL": event.meetingURL?.absoluteString ?? ""
        ]

        let triggerDate = event.startDate.addingTimeInterval(-Double(minutesBefore * 60))

        // Don't schedule if trigger time is in the past
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "event-\(event.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            throw NotificationError.schedulingFailed(error)
        }
    }

    func cancelReminder(for eventId: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["event-\(eventId)"])
    }

    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Snooze

    private func reschedule(eventId: String?, meetingURL: String?, minutes: Int) {
        guard let eventId = eventId else { return }

        let content = UNMutableNotificationContent()
        content.title = "Event Reminder (Snoozed)"
        content.body = "Your event is starting soon"
        content.sound = .default
        content.categoryIdentifier = Self.eventReminderCategory
        content.userInfo = [
            "eventId": eventId,
            "meetingURL": meetingURL ?? ""
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: Double(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "event-\(eventId)-snooze",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let eventId = userInfo["eventId"] as? String
        let meetingURL = userInfo["meetingURL"] as? String

        switch response.actionIdentifier {
        case Self.snooze3Action:
            reschedule(eventId: eventId, meetingURL: meetingURL, minutes: 3)

        case Self.snooze5Action:
            reschedule(eventId: eventId, meetingURL: meetingURL, minutes: 5)

        case Self.snooze10Action:
            reschedule(eventId: eventId, meetingURL: meetingURL, minutes: 10)

        case Self.joinMeetingAction:
            if let urlString = meetingURL, !urlString.isEmpty,
               let url = URL(string: urlString) {
                await MainActor.run {
                    NSWorkspace.shared.open(url)
                }
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped notification body - could open app to event
            break

        case Self.dismissAction:
            // User dismissed - nothing to do
            break

        default:
            break
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
}
