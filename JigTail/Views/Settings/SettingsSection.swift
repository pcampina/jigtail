import SwiftUI

/// The panes shown in the settings window sidebar.
enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case triggers
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .triggers: return "Trigger Conditions"
        case .about: return "About"
        }
    }

    var symbolName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .triggers: return "bolt.fill"
        case .about: return "info"
        }
    }

    var tint: LinearGradient {
        switch self {
        case .general: return LinearGradient(colors: [Token.Color.t2, Token.Color.t3], startPoint: .top, endPoint: .bottom)
        case .triggers: return Token.Gradient.brand
        case .about: return Token.Gradient.lock
        }
    }
}
