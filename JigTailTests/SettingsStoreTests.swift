import XCTest
@testable import JigTail

final class SettingsStoreTests: XCTestCase {
    func testDefaultsWhenEmpty() {
        let suiteName = "JigTailTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.idleThresholdMinutes, 5)
        XCTAssertEqual(store.jiggleIntervalSeconds, 40)
        XCTAssertEqual(store.triggerMode, .manual)
        XCTAssertFalse(store.appRunningTriggerEnabled)
        XCTAssertFalse(store.cpuBusyTriggerEnabled)
        XCTAssertEqual(store.cpuBusyThresholdPercent, 30)
        XCTAssertFalse(store.mediaPlayingTriggerEnabled)
        XCTAssertFalse(store.launchAtLoginEnabled)
        XCTAssertEqual(store.themeOverride, .system)
    }

    func testPersistsChangesAcrossInstances() {
        let suiteName = "JigTailTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.idleThresholdMinutes = 30
        store.jiggleIntervalSeconds = 60
        store.triggerMode = .conditional
        store.appRunningTriggerEnabled = true
        store.appRunningTargetBundleID = "com.apple.Terminal"
        store.cpuBusyThresholdPercent = 50
        store.themeOverride = .dark

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.idleThresholdMinutes, 30)
        XCTAssertEqual(reloaded.jiggleIntervalSeconds, 60)
        XCTAssertEqual(reloaded.triggerMode, .conditional)
        XCTAssertTrue(reloaded.appRunningTriggerEnabled)
        XCTAssertEqual(reloaded.appRunningTargetBundleID, "com.apple.Terminal")
        XCTAssertEqual(reloaded.cpuBusyThresholdPercent, 50)
        XCTAssertEqual(reloaded.themeOverride, .dark)
    }
}
