// Copyright © 2026 Mark Zaros. All Rights Reserved. License: GNU Public License 2.0 only.

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appSettings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Launch automatically at login", isOn: launchAtLoginBinding)
            if let errorMessage = appSettings.launchAtLoginError {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(width: 460, alignment: .topLeading)
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appSettings.launchAtLoginEnabled },
            set: { appSettings.setLaunchAtLogin($0) }
        )
    }
}
