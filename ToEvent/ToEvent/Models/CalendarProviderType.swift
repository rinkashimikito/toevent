import Foundation

enum CalendarProviderType: String, Codable {
    case local
    case google
    case outlook

    var displayName: String {
        switch self {
        case .local:
            return "Local Calendar"
        case .google:
            return "Google Calendar"
        case .outlook:
            return "Microsoft Outlook"
        }
    }

    var symbolName: String {
        switch self {
        case .local:
            return "calendar"
        case .google:
            return "g.circle"
        case .outlook:
            return "m.circle"
        }
    }
}
