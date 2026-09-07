import AppKit
import Foundation
import SwiftUI

enum TriggerMode: String, CaseIterable, Identifiable {
    case manual
    case conditional
    var id: String { rawValue }
}

enum ThemeOverride: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// The DS's `Token.Color` values resolve through `NSColor(dynamicProvider:)` against the
    /// process's actual `NSApp.appearance`, not SwiftUI's `\.colorScheme` environment — so
    /// `.preferredColorScheme` alone never touches them. Setting this on `NSApp` is what
    /// actually re-themes the app; `nil` restores following the system.
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

/// User-configurable, persisted settings. Takes a `UserDefaults` instance (default `.standard`)
/// so tests can inject an isolated suite instead of touching real user defaults.
final class SettingsStore: ObservableObject {
    @Published var idleThresholdMinutes: Int {
        didSet { defaults.set(idleThresholdMinutes, forKey: Keys.idleThresholdMinutes) }
    }

    @Published var jiggleIntervalSeconds: Int {
        didSet { defaults.set(jiggleIntervalSeconds, forKey: Keys.jiggleIntervalSeconds) }
    }

    @Published var triggerMode: TriggerMode {
        didSet { defaults.set(triggerMode.rawValue, forKey: Keys.triggerMode) }
    }

    @Published var appRunningTriggerEnabled: Bool {
        didSet { defaults.set(appRunningTriggerEnabled, forKey: Keys.appRunningTriggerEnabled) }
    }

    @Published var appRunningTargetBundleID: String {
        didSet { defaults.set(appRunningTargetBundleID, forKey: Keys.appRunningTargetBundleID) }
    }

    @Published var appRunningTargetDisplayName: String {
        didSet { defaults.set(appRunningTargetDisplayName, forKey: Keys.appRunningTargetDisplayName) }
    }

    @Published var cpuBusyTriggerEnabled: Bool {
        didSet { defaults.set(cpuBusyTriggerEnabled, forKey: Keys.cpuBusyTriggerEnabled) }
    }

    @Published var cpuBusyThresholdPercent: Int {
        didSet { defaults.set(cpuBusyThresholdPercent, forKey: Keys.cpuBusyThresholdPercent) }
    }

    @Published var mediaPlayingTriggerEnabled: Bool {
        didSet { defaults.set(mediaPlayingTriggerEnabled, forKey: Keys.mediaPlayingTriggerEnabled) }
    }

    @Published var launchAtLoginEnabled: Bool {
        didSet { defaults.set(launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled) }
    }

    @Published var themeOverride: ThemeOverride {
        didSet {
            defaults.set(themeOverride.rawValue, forKey: Keys.themeOverride)
            NSApp.appearance = themeOverride.nsAppearance
        }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let idleThresholdMinutes = "idleThresholdMinutes"
        static let jiggleIntervalSeconds = "jiggleIntervalSeconds"
        static let triggerMode = "triggerMode"
        static let appRunningTriggerEnabled = "appRunningTriggerEnabled"
        static let appRunningTargetBundleID = "appRunningTargetBundleID"
        static let appRunningTargetDisplayName = "appRunningTargetDisplayName"
        static let cpuBusyTriggerEnabled = "cpuBusyTriggerEnabled"
        static let cpuBusyThresholdPercent = "cpuBusyThresholdPercent"
        static let mediaPlayingTriggerEnabled = "mediaPlayingTriggerEnabled"
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let themeOverride = "themeOverride"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        idleThresholdMinutes = defaults.object(forKey: Keys.idleThresholdMinutes) as? Int ?? 5
        jiggleIntervalSeconds = defaults.object(forKey: Keys.jiggleIntervalSeconds) as? Int ?? 40
        triggerMode = (defaults.string(forKey: Keys.triggerMode)).flatMap(TriggerMode.init) ?? .manual
        appRunningTriggerEnabled = defaults.object(forKey: Keys.appRunningTriggerEnabled) as? Bool ?? false
        appRunningTargetBundleID = defaults.string(forKey: Keys.appRunningTargetBundleID) ?? ""
        appRunningTargetDisplayName = defaults.string(forKey: Keys.appRunningTargetDisplayName) ?? ""
        cpuBusyTriggerEnabled = defaults.object(forKey: Keys.cpuBusyTriggerEnabled) as? Bool ?? false
        cpuBusyThresholdPercent = defaults.object(forKey: Keys.cpuBusyThresholdPercent) as? Int ?? 30
        mediaPlayingTriggerEnabled = defaults.object(forKey: Keys.mediaPlayingTriggerEnabled) as? Bool ?? false
        launchAtLoginEnabled = defaults.object(forKey: Keys.launchAtLoginEnabled) as? Bool ?? false
        themeOverride = (defaults.string(forKey: Keys.themeOverride)).flatMap(ThemeOverride.init) ?? .system

        // `didSet` doesn't fire during the initializer's own stored-property assignment above,
        // so the persisted theme has to be applied to NSApp explicitly on launch.
        NSApp.appearance = themeOverride.nsAppearance
    }
}
