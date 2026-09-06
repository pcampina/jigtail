import Foundation
import ServiceManagement

/// Thin wrapper over SMAppService for "launch JigTail at login."
final class LaunchAtLoginService: ObservableObject {
    enum Status: Equatable {
        case disabled
        case enabled
        /// Registered, but the user needs to approve it in System Settings > Login Items.
        case requiresApproval
    }

    @Published private(set) var status: Status = .disabled

    init() {
        refresh()
    }

    func refresh() {
        switch SMAppService.mainApp.status {
        case .enabled:
            status = .enabled
        case .requiresApproval:
            status = .requiresApproval
        default:
            status = .disabled
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                }
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration can legitimately fail (e.g. already in the desired state, or the
            // user needs to approve it) — refresh() below reflects whatever actually happened.
        }
        refresh()
    }

    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
