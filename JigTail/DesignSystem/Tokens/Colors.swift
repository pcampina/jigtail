import AppKit
import SwiftUI

extension SwiftUI.Color {
    /// 0xRRGGBB, matching the hex literals used in the family's shared tokens.
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Appearance-aware color. Resolves through `NSColor(dynamicProvider:)` rather than
    /// SwiftUI's `\.colorScheme`, so it follows `NSApp.appearance` — which is what the
    /// Theme setting actually sets (see `ThemeOverride.nsAppearance`).
    init(light: SwiftUI.Color, dark: SwiftUI.Color) {
        self.init(NSColor(name: nil, dynamicProvider: { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        }))
    }
}

/// Design tokens, kept value-for-value identical to PawseKeys' `Theme` so the two apps read
/// as one family. PawseKeys carries these in an `@Environment(\.theme)` struct with `.light`
/// and `.dark` presets; JigTail expresses the same pairs as dynamic colors instead, which is
/// equivalent at render time and keeps call sites free of a theme parameter.
enum Token {
    enum Color {
        // MARK: Brand (theme-independent)

        /// PawseKeys `brandOrange`.
        static let coral = SwiftUI.Color(hex: 0xFF6B35)
        /// PawseKeys `brandPink`.
        static let pink = SwiftUI.Color(hex: 0xFF3D7F)
        /// PawseKeys `lockedColor` — the family's "active right now" green.
        static let mint = SwiftUI.Color(hex: 0x00E5A0)
        /// PawseKeys `lockedCyan` — the far end of the active gradient.
        static let cyan = SwiftUI.Color(hex: 0x00B8D9)
        /// PawseKeys `unlockedColor`.
        static let red = SwiftUI.Color(hex: 0xFF4757)

        // MARK: Surfaces

        static let page = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xEEF0F5),
            dark: SwiftUI.Color(hex: 0x141519)
        )
        static let card = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xE8EBF2),
            dark: SwiftUI.Color(hex: 0x1C1E26)
        )

        /// Top stop of a raised surface's gradient (PawseKeys `surfaceGradientLight`).
        static let surfaceTop = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xF2F4FA),
            dark: SwiftUI.Color(hex: 0x2C303E)
        )
        /// Bottom stop of a raised surface's gradient (PawseKeys `surfaceGradientDark`).
        static let surfaceBottom = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xE0E4EE),
            dark: SwiftUI.Color(hex: 0x1E2230)
        )

        /// Top stop of the knob's inner dish (PawseKeys `dishGradientLight`).
        static let dishTop = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xEDF0F7),
            dark: SwiftUI.Color(hex: 0x22262F)
        )
        /// Bottom stop of the knob's inner dish (PawseKeys `dishGradientDark`).
        static let dishBottom = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xDDE1EC),
            dark: SwiftUI.Color(hex: 0x171A22)
        )

        /// Inactive pill fill — deliberately distinct from `surfaceTop`/`surfaceBottom` so a
        /// dark pill reads darker than the raised surface behind it.
        static let pillInactiveTop = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xEDF0F7),
            dark: SwiftUI.Color(hex: 0x2A2E3C)
        )
        static let pillInactiveBottom = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0xDDE2ED),
            dark: SwiftUI.Color(hex: 0x222635)
        )

        /// Kept as aliases so existing card/settings-group call sites stay meaningful.
        static let raised = surfaceTop
        static let inset = dishBottom

        static let line = SwiftUI.Color(
            light: SwiftUI.Color(.sRGB, red: 160 / 255, green: 175 / 255, blue: 205 / 255, opacity: 0.4),
            dark: SwiftUI.Color.white.opacity(0.09)
        )

        // MARK: Text

        static let t1 = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0x18191F),
            dark: SwiftUI.Color(hex: 0xE8EAF2)
        )
        static let t2 = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0x6B7487),
            dark: SwiftUI.Color(hex: 0xA0AABB)
        )
        static let t3 = SwiftUI.Color(
            light: SwiftUI.Color(hex: 0x9BA5B8),
            dark: SwiftUI.Color(hex: 0x6E7A90)
        )

        // MARK: Neumorphic shadow pairs

        static let outerDarkShadow = SwiftUI.Color(
            light: SwiftUI.Color(.sRGB, red: 180 / 255, green: 190 / 255, blue: 210 / 255, opacity: 0.7),
            dark: SwiftUI.Color.black.opacity(0.65)
        )
        static let outerLightShadow = SwiftUI.Color(
            light: SwiftUI.Color.white,
            dark: SwiftUI.Color.white.opacity(0.07)
        )
        static let innerDarkShadow = SwiftUI.Color(
            light: SwiftUI.Color(.sRGB, red: 180 / 255, green: 190 / 255, blue: 210 / 255, opacity: 0.55),
            dark: SwiftUI.Color.black.opacity(0.55)
        )
        static let innerLightShadow = SwiftUI.Color(
            light: SwiftUI.Color.white.opacity(0.9),
            dark: SwiftUI.Color.white.opacity(0.05)
        )
    }
}
