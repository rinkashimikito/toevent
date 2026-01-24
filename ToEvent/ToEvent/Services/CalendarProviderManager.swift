import Foundation
import Combine

final class CalendarProviderManager: ObservableObject {
    static let shared = CalendarProviderManager()

    @Published private(set) var providers: [any CalendarProvider] = []
    @Published private(set) var expiredAccounts: [CalendarAccount] = []

    private let localProvider = LocalCalendarProvider()
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadProviders()
        observeAccountChanges()
    }

    func loadProviders() {
        var newProviders: [any CalendarProvider] = [localProvider]

        for account in AuthService.shared.accounts {
            switch account.providerType {
            case .google:
                newProviders.append(GoogleCalendarProvider(account: account))
            case .outlook:
                newProviders.append(OutlookCalendarProvider(account: account))
            case .local:
                break
            }
        }

        providers = newProviders
    }

    func addProvider(for account: CalendarAccount) {
        let provider: any CalendarProvider
        switch account.providerType {
        case .google:
            provider = GoogleCalendarProvider(account: account)
        case .outlook:
            provider = OutlookCalendarProvider(account: account)
        case .local:
            return
        }

        providers.append(provider)
    }

    func removeProvider(for accountId: String) {
        providers.removeAll { $0.account.id == accountId }
        EventCacheService.shared.clearCache(for: accountId)
        expiredAccounts.removeAll { $0.id == accountId }
    }

    func fetchAllEvents(
        from startDate: Date,
        to endDate: Date,
        enabledCalendarIDs: Set<String>?
    ) async -> [Event] {
        var allEvents: [Event] = []
        var newExpiredAccounts: [CalendarAccount] = []

        for provider in providers {
            do {
                let calendarIDs = enabledCalendarIDs.map { Array($0) }
                let events = try await provider.fetchEvents(
                    from: startDate,
                    to: endDate,
                    calendarIDs: calendarIDs
                )
                allEvents.append(contentsOf: events)

                if provider.providerType != .local {
                    try? EventCacheService.shared.cacheEvents(events, for: provider.account.id)
                }
            } catch {
                if isAuthExpiredError(error) {
                    newExpiredAccounts.append(provider.account)
                }

                if provider.providerType != .local {
                    let cached = EventCacheService.shared.loadCachedEvents(for: provider.account.id)
                    allEvents.append(contentsOf: cached)
                }
            }
        }

        let expired = newExpiredAccounts
        await MainActor.run {
            self.expiredAccounts = expired
        }

        return allEvents.sorted { $0.startDate < $1.startDate }
    }

    func fetchAllCalendars() async -> [CalendarInfo] {
        var allCalendars: [CalendarInfo] = []

        for provider in providers {
            do {
                let calendars = try await provider.fetchCalendars()
                allCalendars.append(contentsOf: calendars)
            } catch {
                continue
            }
        }

        return allCalendars
    }

    private func observeAccountChanges() {
        AuthService.shared.$accounts
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadProviders()
            }
            .store(in: &cancellables)
    }

    private func isAuthExpiredError(_ error: Error) -> Bool {
        if let googleError = error as? GoogleCalendarError {
            switch googleError {
            case .authExpired, .notAuthenticated:
                return true
            default:
                return false
            }
        }

        if let outlookError = error as? OutlookCalendarError {
            switch outlookError {
            case .authExpired, .notAuthenticated:
                return true
            default:
                return false
            }
        }

        return false
    }
}
