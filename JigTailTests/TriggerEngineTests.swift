import XCTest
@testable import JigTail

private struct StubTrigger: JiggleTrigger {
    let kind: TriggerKind
    let satisfied: Bool
    var isSatisfied: Bool { get async { satisfied } }
}

final class TriggerEngineTests: XCTestCase {
    func testNoEnabledTriggersIsNeverSatisfied() async {
        let engine = TriggerEngine()
        await engine.setTrigger(StubTrigger(kind: .appRunning, satisfied: true))
        // Registered but never enabled.
        let result = await engine.isAnySatisfied()
        XCTAssertFalse(result)
    }

    func testSatisfiedWhenAnyEnabledTriggerIsSatisfied() async {
        let engine = TriggerEngine()
        await engine.setTrigger(StubTrigger(kind: .appRunning, satisfied: false))
        await engine.setTrigger(StubTrigger(kind: .cpuBusy, satisfied: true))
        await engine.setEnabled(.appRunning, enabled: true)
        await engine.setEnabled(.cpuBusy, enabled: true)

        let result = await engine.isAnySatisfied()
        XCTAssertTrue(result)
    }

    func testNotSatisfiedWhenAllEnabledTriggersAreUnsatisfied() async {
        let engine = TriggerEngine()
        await engine.setTrigger(StubTrigger(kind: .appRunning, satisfied: false))
        await engine.setTrigger(StubTrigger(kind: .mediaPlaying, satisfied: false))
        await engine.setEnabled(.appRunning, enabled: true)
        await engine.setEnabled(.mediaPlaying, enabled: true)

        let result = await engine.isAnySatisfied()
        XCTAssertFalse(result)
    }

    func testDisablingATriggerExcludesItEvenIfSatisfied() async {
        let engine = TriggerEngine()
        await engine.setTrigger(StubTrigger(kind: .cpuBusy, satisfied: true))
        await engine.setEnabled(.cpuBusy, enabled: true)
        await engine.setEnabled(.cpuBusy, enabled: false)

        let result = await engine.isAnySatisfied()
        XCTAssertFalse(result)
    }
}
