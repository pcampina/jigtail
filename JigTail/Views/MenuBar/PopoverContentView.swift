import SwiftUI

/// The popover shown when the menu bar icon is clicked. Structure, spacing and type mirror
/// PawseKeys' main window section for section — header, divider, knob area with status row,
/// divider, preset section, divider — so the two apps read as one family.
struct PopoverContentView: View {
    @EnvironmentObject private var coordinator: JiggleCoordinator
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var permissions: PermissionsService

    private let idlePresets = [1, 5, 15, 30, 60]

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 18)
                .padding(.horizontal, 20)
                .padding(.bottom, 18)

            NCXDivider()

            if !permissions.isAccessibilityTrusted {
                permissionBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                NCXDivider()
                    .padding(.top, 16)
            }

            knobArea
                .padding(.top, 20)
                .padding(.bottom, 18)

            NCXDivider()

            idleThresholdSection
                .padding(.top, 16)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            NCXDivider()

            quitButton
                .padding(.top, 12)
                .padding(.bottom, 14)
        }
        .frame(width: 360)
        .background(Token.Color.card)
        .preferredColorScheme(settings.themeOverride.colorScheme)
        .onAppear { permissions.refresh() }
        .alert("Accessibility Access Needed", isPresented: Binding(
            get: { coordinator.showPermissionAlert },
            set: { coordinator.showPermissionAlert = $0 }
        )) {
            Button("Open System Settings") { permissions.openSystemSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("JigTail needs Accessibility access to move your mouse. Turn on JigTail in System Settings > Privacy & Security > Accessibility, then come back and try again.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            AppIconView()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Token.Radius.icon, style: .continuous))
                .neumorphicOuterShadow()

            VStack(alignment: .leading, spacing: 4) {
                Text("JigTail")
                    .font(.system(size: 18, weight: .semibold))
                    .tracking(-0.5)
                    .foregroundStyle(Token.Color.t1)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Text("Keeps your Mac awake \u{00B7} Menu bar")
                    .font(.system(size: 11))
                    .foregroundStyle(Token.Color.t3)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 8)

            settingsButton
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14.0, *) {
            SettingsLink { settingsIcon }
                .buttonStyle(.plain)
                .accessibilityLabel("Open JigTail settings")
        } else {
            Button(action: openLegacySettings) { settingsIcon }
                .buttonStyle(.plain)
                .accessibilityLabel("Open JigTail settings")
        }
    }

    private var settingsIcon: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Token.Color.t2)
            .frame(width: 34, height: 34)
            .background(
                RoundedRectangle(cornerRadius: Token.Radius.btn, style: .continuous)
                    .fill(Token.Gradient.surface)
                    .neumorphicOuterShadow(radius: 5)
            )
    }

    private func openLegacySettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    // MARK: - Permission banner

    private var permissionBanner: some View {
        NCXCard(variant: .inset) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Token.Color.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility access needed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Token.Color.t1)
                    Text("Required so JigTail can move your mouse.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Token.Color.t2)
                }
                Spacer(minLength: 0)
                Button("Grant\u{2026}") {
                    permissions.requestAccess()
                    permissions.openSystemSettings()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Token.Color.red)
            }
        }
    }

    // MARK: - Knob area

    private var knobArea: some View {
        VStack(spacing: 14) {
            NCXKnob(
                isActive: coordinator.state == .activeJiggling,
                countdown: phaseCountdown,
                pulsing: coordinator.hasRecentJiggle
            ) {
                iconForState
            } action: {
                coordinator.toggle()
            }

            statusRow
        }
    }

    @ViewBuilder
    private var iconForState: some View {
        switch coordinator.state {
        case .off:
            WaggingBrandIcon(isWagging: false)
                .opacity(0.4)
        case .idleWaiting:
            WaggingBrandIcon(isWagging: false)
                .opacity(0.7)
        case .activeJiggling:
            WaggingBrandIcon(isWagging: true)
        }
    }

    private var statusRow: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .shadow(color: statusColor.opacity(0.3), radius: 3)

            Text(statusText)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(Token.Color.t2)

            if let countdown = phaseCountdown {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(countdown.remaining(at: context.date).minutesSecondsRemaining)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: Token.Radius.badge, style: .continuous)
                                .fill(statusColor.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: Token.Radius.badge, style: .continuous)
                                        .stroke(statusColor.opacity(0.18), lineWidth: 1)
                                )
                        )
                }

                Text(countdownDetail)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(Token.Color.t2)
            }
        }
        .animation(Token.Animation.section, value: coordinator.state)
    }

    private var statusColor: Color {
        switch coordinator.state {
        case .off: return Token.Color.red
        case .idleWaiting: return Token.Color.t3
        case .activeJiggling: return Token.Color.mint
        }
    }

    private var statusText: String {
        switch coordinator.state {
        case .off: return "Off \u{00B7} Click to start"
        case .idleWaiting: return "Waiting \u{00B7}"
        case .activeJiggling: return "Awake \u{00B7}"
        }
    }

    private var countdownDetail: String {
        switch coordinator.state {
        case .off: return ""
        case .idleWaiting: return "until jiggle"
        case .activeJiggling: return "until next jiggle"
        }
    }

    private var phaseCountdown: JiggleCoordinator.Countdown? {
        coordinator.phaseCountdown
    }

    // MARK: - Preset section

    private var idleThresholdSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("START JIGGLING AFTER")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Token.Color.t3)

                Spacer()
            }

            NCXPillGroup(
                options: idlePresets,
                selection: Binding(
                    get: { settings.idleThresholdMinutes },
                    set: {
                        settings.idleThresholdMinutes = $0
                        coordinator.refreshIdleCountdown()
                    }
                ),
                label: { "\($0)m" }
            )
        }
    }

    private var quitButton: some View {
        Button("Quit JigTail") {
            NSApp.terminate(nil)
        }
        .buttonStyle(.plain)
        .font(.system(size: 11))
        .foregroundStyle(Token.Color.t3)
    }
}

/// The knob's center mark — the actual `MenuBarIcon` asset (the same brand mark as the status
/// bar, theme-aware for free), given a small wag rotation while `isWagging` so it still reads
/// as "actively jiggling."
private struct WaggingBrandIcon: View {
    var isWagging: Bool

    @State private var wagged = false

    var body: some View {
        Image("MenuBarIcon")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .rotationEffect(.degrees(wagged ? 10 : -10), anchor: .bottom)
            .onAppear { if isWagging { startWag() } }
            .onChange(of: isWagging) { newValue in
                if newValue {
                    startWag()
                } else {
                    withAnimation(.easeOut(duration: 0.25)) { wagged = false }
                }
            }
    }

    private func startWag() {
        withAnimation(.easeInOut(duration: 0.32).repeatForever(autoreverses: true)) {
            wagged = true
        }
    }
}
