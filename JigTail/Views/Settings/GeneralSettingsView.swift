import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var launchAtLogin: LaunchAtLoginService

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NCXSettingsGroup {
                NCXSettingsRow(
                    title: "Launch JigTail at login",
                    showDivider: launchAtLogin.status == .requiresApproval
                ) {
                    NCXToggle(isOn: launchAtLoginBinding)
                }

                if launchAtLogin.status == .requiresApproval {
                    NCXSettingsRow(
                        title: "Needs approval in System Settings",
                        showDivider: false
                    ) {
                        Button("Open…") { launchAtLogin.openSystemSettingsLoginItems() }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Token.Color.coral)
                    }
                }
            }

            NCXSettingsGroup(title: "Jiggling") {
                NCXSettingsRow(title: "Idle threshold") {
                    Stepper(value: idleThresholdBinding, in: 1...120) {
                        Text("\(settings.idleThresholdMinutes) min")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Token.Color.t2)
                    }
                }
                NCXSettingsRow(title: "Jiggle interval", showDivider: false) {
                    Stepper(value: jiggleIntervalBinding, in: 10...300, step: 5) {
                        Text("\(settings.jiggleIntervalSeconds)s")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Token.Color.t2)
                    }
                }
            }

            NCXSettingsGroup(title: "Appearance") {
                NCXSettingsRow(title: "Theme", showDivider: false) {
                    NCXPillGroup(
                        options: ThemeOverride.allCases,
                        selection: themeBinding,
                        label: { $0.rawValue.capitalized }
                    )
                    .frame(width: 200)
                }
            }
        }
        .onAppear { launchAtLogin.refresh() }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { settings.launchAtLoginEnabled },
            set: { newValue in
                settings.launchAtLoginEnabled = newValue
                launchAtLogin.setEnabled(newValue)
            }
        )
    }

    private var idleThresholdBinding: Binding<Int> {
        Binding(get: { settings.idleThresholdMinutes }, set: { settings.idleThresholdMinutes = $0 })
    }

    private var jiggleIntervalBinding: Binding<Int> {
        Binding(get: { settings.jiggleIntervalSeconds }, set: { settings.jiggleIntervalSeconds = $0 })
    }

    private var themeBinding: Binding<ThemeOverride> {
        Binding(get: { settings.themeOverride }, set: { settings.themeOverride = $0 })
    }
}
