import SwiftUI
import AppKit

struct AboutSettingsView: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    private let githubURL = "https://github.com/rinkashimikito/toevent"

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
                .padding(.top, 20)

            Text("ToEvent")
                .font(.title)
                .fontWeight(.semibold)

            VStack(spacing: 4) {
                Text("Version \(version) (\(build))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button(action: openGitHub) {
                    Label("View on GitHub", systemImage: "link")
                }
                .buttonStyle(.link)

                Button(action: openGitHubIssues) {
                    Label("Report an Issue", systemImage: "exclamationmark.bubble")
                }
                .buttonStyle(.link)
            }

            Spacer()

            Text("Menu bar app showing your next calendar event with countdown")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openGitHub() {
        if let url = URL(string: githubURL) {
            NSWorkspace.shared.open(url)
        }
    }

    private func openGitHubIssues() {
        if let url = URL(string: "\(githubURL)/issues") {
            NSWorkspace.shared.open(url)
        }
    }
}
