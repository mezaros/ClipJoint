// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import Combine
import Foundation
import ServiceManagement

/// App-level preference state currently centered on login-item registration.
@MainActor
final class AppSettings: ObservableObject {
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published private(set) var launchAtLoginError: String?

    private let loginItemManager: LoginItemManager

    convenience init() {
        self.init(loginItemManager: .shared)
    }

    init(loginItemManager: LoginItemManager) {
        self.loginItemManager = loginItemManager
        launchAtLoginEnabled = loginItemManager.isEnabled
        launchAtLoginError = nil
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            launchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginError = nil
        } catch {
            launchAtLoginEnabled = loginItemManager.isEnabled
            launchAtLoginError = error.localizedDescription
        }
    }
}

@MainActor
final class LoginItemManager {
    static let shared = LoginItemManager()

    private init() {}

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        let status = SMAppService.mainApp.status

        if enabled {
            if status == .enabled {
                return
            }

            try SMAppService.mainApp.register()

            switch SMAppService.mainApp.status {
            case .enabled:
                return
            case .requiresApproval:
                throw LoginItemError.requiresApproval
            case .notFound:
                throw LoginItemError.notFound
            case .notRegistered:
                throw LoginItemError.registrationFailed
            @unknown default:
                throw LoginItemError.registrationFailed
            }
        } else {
            if status == .notRegistered || status == .notFound {
                return
            }

            try SMAppService.mainApp.unregister()
        }
    }
}

enum LoginItemError: LocalizedError {
    case requiresApproval
    case notFound
    case registrationFailed

    var errorDescription: String? {
        switch self {
        case .requiresApproval:
            return "Open System Settings > General > Login Items and allow ClipJoint to finish enabling launch at login."
        case .notFound:
            return "Launch at login is only available after ClipJoint is installed in /Applications."
        case .registrationFailed:
            return "ClipJoint could not enable launch at login. Please try again."
        }
    }
}
