import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct TriggersSettingsView: View {
    @EnvironmentObject private var coordinator: JiggleCoordinator
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            NCXSettingsGroup(title: "Mode") {
                NCXSettingsRow(title: "Trigger mode", showDivider: false) {
                    NCXPillGroup(
                        options: [TriggerMode.manual, .conditional],
                        selection: modeBinding,
                        label: { $0 == .manual ? "Manual" : "Conditional" }
                    )
                    .frame(width: 200)
                }
            }

            if settings.triggerMode == .conditional {
                NCXSettingsGroup(title: "Conditions") {
                    NCXSettingsRow(
                        title: "Specific app is running",
                        subtitle: settings.appRunningTargetDisplayName.isEmpty
                            ? "No app chosen"
                            : settings.appRunningTargetDisplayName
                    ) {
                        NCXToggle(isOn: appRunningBinding)
                    }
                    NCXSettingsRow(title: "Choose app…") {
                        Button("Choose…") { chooseApp() }
                            .buttonStyle(.plain)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Token.Color.t2)
                    }
                    NCXSettingsRow(title: "CPU is busy") {
                        NCXToggle(isOn: cpuBusyBinding)
                    }
                    NCXSettingsRow(title: "CPU threshold") {
                        Stepper(value: cpuThresholdBinding, in: 5...90, step: 5) {
                            Text("\(settings.cpuBusyThresholdPercent)%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Token.Color.t2)
                        }
                    }
                    NCXSettingsRow(title: "Music or Spotify is playing", showDivider: false) {
                        NCXToggle(isOn: mediaBinding)
                    }
                }
            } else {
                Text("Jiggling starts once you've been idle long enough — no extra conditions.")
                    .font(.system(size: 12))
                    .foregroundStyle(Token.Color.t3)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var modeBinding: Binding<TriggerMode> {
        Binding(get: { settings.triggerMode }, set: {
            settings.triggerMode = $0
            coordinator.refreshTriggerConfiguration()
        })
    }

    private var appRunningBinding: Binding<Bool> {
        Binding(get: { settings.appRunningTriggerEnabled }, set: {
            settings.appRunningTriggerEnabled = $0
            coordinator.refreshTriggerConfiguration()
        })
    }

    private var cpuBusyBinding: Binding<Bool> {
        Binding(get: { settings.cpuBusyTriggerEnabled }, set: {
            settings.cpuBusyTriggerEnabled = $0
            coordinator.refreshTriggerConfiguration()
        })
    }

    private var cpuThresholdBinding: Binding<Int> {
        Binding(get: { settings.cpuBusyThresholdPercent }, set: {
            settings.cpuBusyThresholdPercent = $0
            coordinator.refreshTriggerConfiguration()
        })
    }

    private var mediaBinding: Binding<Bool> {
        Binding(get: { settings.mediaPlayingTriggerEnabled }, set: {
            settings.mediaPlayingTriggerEnabled = $0
            coordinator.refreshTriggerConfiguration()
        })
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let bundle = Bundle(url: url)
        let displayName = (bundle?.infoDictionary?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent

        settings.appRunningTargetBundleID = bundle?.bundleIdentifier ?? ""
        settings.appRunningTargetDisplayName = displayName
        coordinator.refreshTriggerConfiguration()
    }
}
