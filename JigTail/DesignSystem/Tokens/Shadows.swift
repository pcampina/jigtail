import SwiftUI

/// Which neumorphic treatment a surface gets: pushed up out of the page, or pressed into it.
enum NeumorphicVariant: Equatable {
    case raised
    case inset
}

extension View {
    /// PawseKeys' `neumorphicOuterShadow`: a dark shadow down-right plus a light one up-left.
    /// JigTail previously approximated this with a hairline edge stroke because its palette
    /// was too low-contrast for shadows alone to register; on the family palette the real
    /// two-shadow recipe reads correctly, so the stroke is gone.
    func neumorphicOuterShadow(radius: CGFloat = 8) -> some View {
        self
            .shadow(color: Token.Color.outerDarkShadow, radius: radius, x: 6, y: 6)
            .shadow(color: Token.Color.outerLightShadow, radius: radius * 0.75, x: -4, y: -4)
    }

    /// The tighter, closer-in pair PawseKeys uses on the knob's dish and on inset banners.
    func neumorphicInnerShadow() -> some View {
        self
            .shadow(color: Token.Color.innerDarkShadow, radius: 6, x: 4, y: 4)
            .shadow(color: Token.Color.innerLightShadow, radius: 4, x: -2, y: -2)
    }

    @ViewBuilder
    func neumorphic(_ variant: NeumorphicVariant) -> some View {
        switch variant {
        case .raised: neumorphicOuterShadow()
        case .inset: neumorphicInnerShadow()
        }
    }
}
