import Foundation
import Combine
import AppKit

final class SystemStateService: ObservableObject {
    static let shared = SystemStateService()

    @Published private(set) var isScreenLocked = false
    let didWake = PassthroughSubject<Void, Never>()

    private init() {
        observeLockState()
        observeWake()
    }

    private func observeLockState() {
        let dnc = DistributedNotificationCenter.default()

        dnc.addObserver(
            forName: .init("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = true
        }

        dnc.addObserver(
            forName: .init("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = false
        }
    }

    private func observeWake() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isScreenLocked = false
            self?.didWake.send()
        }
    }
}
