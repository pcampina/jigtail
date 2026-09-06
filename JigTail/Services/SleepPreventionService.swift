import Foundation
import IOKit.pwr_mgt

/// Holds an IOPMAssertion for the duration of an active/timed session as a belt-and-suspenders
/// guard against sleep — independent of JiggleService, since a synthesized HID event resets the
/// screensaver/idle timer but an IOPMAssertion is what explicitly tells powerd not to sleep.
final class SleepPreventionService {
    private var assertionID: IOPMAssertionID = 0
    private(set) var isActive = false

    func start(reason: String = "JigTail is keeping this Mac awake") {
        guard !isActive else { return }
        var newAssertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &newAssertionID
        )
        guard result == kIOReturnSuccess else { return }
        assertionID = newAssertionID
        isActive = true
    }

    func stop() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        isActive = false
    }
}
