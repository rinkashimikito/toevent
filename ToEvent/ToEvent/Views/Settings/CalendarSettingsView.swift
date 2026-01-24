import SwiftUI

struct CalendarSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var providerManager = CalendarProviderManager.shared
    @ObservedObject private var authService = AuthService.shared

    @State private var calendars: [CalendarInfo] = []
    @State private var showingAddAccount = false

    var body: some View {
        VStack(spacing: 0) {
            // Re-authentication warning
            if !providerManager.expiredAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Re-authentication Required")
                        .font(.headline)
                    ForEach(providerManager.expiredAccounts, id: \.id) { account in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(account.displayName) needs re-authentication")
                            Spacer()
                            Button("Sign In") {
                                reauthenticate(account)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding()
            }

            // Connected accounts
            if !authService.accounts.isEmpty {
                Form {
                    Section("Connected Accounts") {
                        ForEach(authService.accounts, id: \.id) { account in
                            HStack {
                                Image(systemName: account.providerType.symbolName)
                                    .frame(width: 20)
                                VStack(alignment: .leading) {
                                    Text(account.displayName)
                                    Text(account.email)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Remove") {
                                    removeAccount(account)
                                }
                                .foregroundColor(.red)
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(height: CGFloat(authService.accounts.count * 50 + 60))
            }

            // Calendar selection
            HStack {
                Text("Drag to reorder priority")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
                Button {
                    showingAddAccount = true
                } label: {
                    Label("Add Account", systemImage: "plus.circle")
                }
                .sheet(isPresented: $showingAddAccount) {
                    AddAccountSheet { account in
                        CalendarProviderManager.shared.addProvider(for: account)
                        loadCalendars()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Calendar list
            if calendars.isEmpty {
                Text("No calendars available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                calendarList
            }
        }
        .onAppear {
            loadCalendars()
        }
    }

    private var sortedCalendars: [CalendarInfo] {
        calendars.sorted { a, b in
            let aIndex = appState.calendarPriority.firstIndex(of: a.id) ?? Int.max
            let bIndex = appState.calendarPriority.firstIndex(of: b.id) ?? Int.max
            return aIndex < bIndex
        }
    }

    @ViewBuilder
    private var calendarList: some View {
        List {
            ForEach(sortedCalendars) { calendar in
                calendarRow(for: calendar)
            }
            .onMove(perform: moveCalendar)
        }
        .listStyle(.inset)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func calendarRow(for calendar: CalendarInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: calendar.providerType.symbolName)
                .foregroundColor(.secondary)
                .frame(width: 16)

            Circle()
                .fill(Color(cgColor: calendar.color))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(calendar.title)
                    .lineLimit(1)

                Text(calendar.source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: binding(for: calendar.id))
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 2)
    }

    private func moveCalendar(from source: IndexSet, to destination: Int) {
        var ordered = sortedCalendars.map { $0.id }
        ordered.move(fromOffsets: source, toOffset: destination)
        appState.calendarPriority = ordered
        appState.refreshEvents()
    }

    private func binding(for calendarID: String) -> Binding<Bool> {
        Binding(
            get: {
                isCalendarEnabled(calendarID)
            },
            set: { newValue in
                setCalendarEnabled(calendarID, enabled: newValue)
            }
        )
    }

    private func isCalendarEnabled(_ calendarID: String) -> Bool {
        guard let enabledIDs = appState.enabledCalendarIDs else {
            return true
        }
        return enabledIDs.contains(calendarID)
    }

    private func setCalendarEnabled(_ calendarID: String, enabled: Bool) {
        let allCalendarIDs = Set(calendars.map { $0.id })

        if enabled {
            if var enabledIDs = appState.enabledCalendarIDs {
                enabledIDs.insert(calendarID)
                if enabledIDs == allCalendarIDs {
                    appState.enabledCalendarIDs = nil
                } else {
                    appState.enabledCalendarIDs = enabledIDs
                }
            }
        } else {
            if appState.enabledCalendarIDs == nil {
                var enabledIDs = allCalendarIDs
                enabledIDs.remove(calendarID)
                appState.enabledCalendarIDs = enabledIDs
            } else {
                appState.enabledCalendarIDs?.remove(calendarID)
            }
        }
        appState.refreshEvents()
    }

    private func loadCalendars() {
        Task {
            let allCalendars = await CalendarProviderManager.shared.fetchAllCalendars()
            await MainActor.run {
                calendars = allCalendars
                appState.initializeCalendarPriority(with: calendars)
            }
        }
    }

    private func removeAccount(_ account: CalendarAccount) {
        do {
            try authService.deleteAccount(account.id)
            providerManager.removeProvider(for: account.id)
            loadCalendars()
        } catch {
            print("Failed to remove account: \(error)")
        }
    }

    private func reauthenticate(_ account: CalendarAccount) {
        guard let window = NSApp.keyWindow else { return }

        Task {
            do {
                _ = try await authService.startOAuthFlow(
                    for: account.providerType,
                    presentingWindow: window
                )
                loadCalendars()
            } catch {
                print("Re-authentication failed: \(error)")
            }
        }
    }
}

extension CalendarSettingsView {
    static let pane: SettingsPane = SettingsPane(
        identifier: SettingsPaneIdentifier("calendars"),
        title: "Calendars",
        toolbarIcon: NSImage(systemSymbolName: "calendar", accessibilityDescription: "Calendars")!
    ) {
        CalendarSettingsView()
    }
}
