import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("What's New in ToEvent")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version \(WhatsNewCheck.currentVersion)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ChangelogSection(
                        title: "Initial Release",
                        items: [
                            "Live countdown timer in menu bar",
                            "Color-coded urgency warnings",
                            "Google Calendar and Outlook integration",
                            "One-click meeting join",
                            "Event notifications with snooze",
                            "Focus mode filtering",
                            "Quick-add events"
                        ]
                    )
                }
                .padding()
            }
            .frame(maxHeight: 300)

            Button("Continue") {
                WhatsNewCheck.markAsSeen()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 400)
    }
}

struct ChangelogSection: View {
    let title: String
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text(item)
                        .font(.body)
                }
            }
        }
    }
}
