import Darwin
import Foundation

/// Satisfied while overall CPU load is at or above a threshold — for keeping a Mac awake
/// through a long compile/render job. `NSProcessInfo` doesn't expose system-wide CPU load,
/// so this reads it straight from the Mach host_statistics call, diffing two consecutive
/// samples (tick counts are cumulative since boot, not an instantaneous reading).
final class CPUBusyTrigger: JiggleTrigger {
    let kind = TriggerKind.cpuBusy
    var thresholdPercent: Double

    private var previousSample: host_cpu_load_info?

    init(thresholdPercent: Double = 30) {
        self.thresholdPercent = thresholdPercent
    }

    var isSatisfied: Bool {
        get async {
            guard let sample = Self.currentSample() else { return false }
            defer { previousSample = sample }
            guard let previous = previousSample else { return false }
            return Self.busyPercent(from: previous, to: sample) >= thresholdPercent
        }
    }

    private static func currentSample() -> host_cpu_load_info? {
        var size = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        var info = host_cpu_load_info()
        let result = withUnsafeMutablePointer(to: &info) { infoPointer -> kern_return_t in
            infoPointer.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { intPointer in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPointer, &size)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return info
    }

    private static func busyPercent(from previous: host_cpu_load_info, to current: host_cpu_load_info) -> Double {
        let userDelta = Double(current.cpu_ticks.0 &- previous.cpu_ticks.0)
        let systemDelta = Double(current.cpu_ticks.1 &- previous.cpu_ticks.1)
        let idleDelta = Double(current.cpu_ticks.2 &- previous.cpu_ticks.2)
        let niceDelta = Double(current.cpu_ticks.3 &- previous.cpu_ticks.3)

        let totalDelta = userDelta + systemDelta + idleDelta + niceDelta
        guard totalDelta > 0 else { return 0 }

        let busyDelta = userDelta + systemDelta + niceDelta
        return (busyDelta / totalDelta) * 100
    }
}
