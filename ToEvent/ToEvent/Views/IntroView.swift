import SwiftUI
import EventKit

struct IntroView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var permissionDenied = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            VStack(spacing: 8) {
                Text("Never miss a meeting")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("ToEvent shows your next calendar event in the menu bar so you always know what's coming up.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            if permissionDenied {
                VStack(spacing: 12) {
                    Text("Calendar access was denied")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Button("Open System Settings") {
                        openPrivacySettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button("Get Started") {
                    Task {
                        await requestPermission()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
                .frame(height: 24)
        }
        .frame(width: 320, height: 400)
    }

    private func requestPermission() async {
        let granted = await CalendarService.shared.requestAccess()

        await MainActor.run {
            if granted {
                appState.hasCompletedIntro = true
                appState.refreshEvents()
                dismiss()
            } else {
                permissionDenied = true
            }
        }
    }

    private func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}
