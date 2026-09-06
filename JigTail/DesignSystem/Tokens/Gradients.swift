import SwiftUI

extension Token {
    enum Gradient {
        /// orange -> pink, topLeading to bottomTrailing. PawseKeys `Theme.brandGradient`;
        /// marks selection/interaction across the family (active pills, toggles).
        static let brand = LinearGradient(
            colors: [Token.Color.coral, Token.Color.pink],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// green -> cyan. The family's "active right now" gradient — PawseKeys uses it for
        /// the locked state, JigTail for actively jiggling.
        static let lock = LinearGradient(
            colors: [Token.Color.mint, Token.Color.cyan],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// The same green -> cyan sweep as `lock`, but swept around the ring so the arc's
        /// color tracks its angle (PawseKeys' progress-ring gradient).
        static let ringActive = AngularGradient(
            gradient: SwiftUI.Gradient(stops: [
                .init(color: Token.Color.mint, location: 0),
                .init(color: Token.Color.cyan, location: 1)
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )

        /// A raised neumorphic surface (buttons, knob body, pair/settings chip).
        static let surface = LinearGradient(
            colors: [Token.Color.surfaceTop, Token.Color.surfaceBottom],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// The knob's concave inner dish — note the stops run dark to light, the reverse of
        /// `surface`, which is what sells the "pressed in" read.
        static let dish = LinearGradient(
            colors: [Token.Color.dishBottom, Token.Color.dishTop],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        /// An unselected pill.
        static let pillInactive = LinearGradient(
            colors: [Token.Color.pillInactiveTop, Token.Color.pillInactiveBottom],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    enum Glow {
        static let brand = Token.Color.pink.opacity(0.28)
        static let lock = Token.Color.mint.opacity(0.22)
        static let red = Token.Color.red.opacity(0.20)
    }
}
