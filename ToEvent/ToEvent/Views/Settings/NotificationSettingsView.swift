import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Enable event reminders", isOn: $appState.notificationsEnabled)
                    .disabled(!notificationService.isAuthorized)

                if !notificationService.isAuthorized {
                    permissionWarning
                }

                if appState.notificationsEnabled {
                    reminderTimePicker
                    soundPicker
                }
            }

            Section("Alert Style") {
                alertStyleInfo
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var permissionWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Notification permission required")
                    .foregroundColor(.secondary)
            }

            Button("Request Permission") {
                Task {
                    _ = try? await notificationService.requestPermission()
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var reminderTimePicker: some View {
        Picker("Remind me", selection: $appState.reminderMinutes) {
            Text("5 minutes before").tag(5)
            Text("10 minutes before").tag(10)
            Text("15 minutes before").tag(15)
            Text("30 minutes before").tag(30)
            Text("1 hour before").tag(60)
        }
        .pickerStyle(.menu)
    }

    private var soundPicker: some View {
        Picker("Sound", selection: $appState.notificationSound) {
            ForEach(AppState.NotificationSoundOption.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.menu)
    }

    private var alertStyleInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                Text("Notifications stay visible until dismissed only when using \"Alerts\" style")
                    .font(.callout)
                    .fontWeight(.medium)
            }

            Divider()

            Text("To configure persistent notifications:")
                .foregroundColor(.secondary)
                .font(.callout)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text("1.")
                        .frame(width: 20)
                    Text("Open System Settings > Notifications > ToEvent")
                }
                HStack(alignment: .top) {
                    Text("2.")
                        .frame(width: 20)
                    Text("Set \"ToEvent alert style\" to \"Alerts\" (not \"Banners\")")
                }
            }
            .font(.callout)
            .foregroundColor(.secondary)

            HStack {
                Button("Open Notification Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }

                Text("Then search for \"ToEvent\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

extension NotificationSettingsView {
    static let pane: SettingsPane = SettingsPane(
        identifier: SettingsPaneIdentifier("notifications"),
        title: "Notifications",
        toolbarIcon: NSImage(systemSymbolName: "bell", accessibilityDescription: "Notifications")!
    ) {
        NotificationSettingsView()
    }
}
