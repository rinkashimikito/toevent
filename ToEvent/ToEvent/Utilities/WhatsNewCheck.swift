import Foundation

struct WhatsNewCheck {
    private static let lastVersionKey = "lastSeenVersion"

    static func shouldShowWhatsNew() -> Bool {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let lastVersion = UserDefaults.standard.string(forKey: lastVersionKey)

        if lastVersion == nil {
            markAsSeen()
            return false
        }
        return lastVersion != currentVersion
    }

    static func markAsSeen() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        UserDefaults.standard.set(currentVersion, forKey: lastVersionKey)
    }

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
}
