import SwiftUI
import EventKit

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var startDate = Date().addingTimeInterval(3600)

    var body: some View {
        VStack(spacing: 16) {
            Text("Quick Add Event")
                .font(.headline)

            TextField("Event title", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker(
                "Start time",
                selection: $startDate,
                displayedComponents: [.date, .hourAndMinute]
            )

            HStack {
                Button("Cancel") {
                    dismiss()
                }

                Spacer()

                Button("Add in Calendar") {
                    openInCalendarApp()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty)
            }
        }
        .padding()
        .frame(width: 300)
    }

    private func openInCalendarApp() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
        let dateString = formatter.string(from: startDate)

        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Calendar"
            activate
            set newEvent to make new event at end of events of calendar 1 with properties {summary:"\(escapedTitle)", start date:date "\(dateString)"}
            show newEvent
        end tell
        """

        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            if error != nil {
                if let url = URL(string: "x-apple-calendar://") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
