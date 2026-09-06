import CoreGraphics

extension Token {
    /// Corner radii as used across the family: 16 for banner/section cards, 14 for the app
    /// icon tile, 10 for pills and chips, 9 for the toggle track, 6 for the countdown badge.
    enum Radius {
        static let card: CGFloat = 16
        static let icon: CGFloat = 14
        static let btn: CGFloat = 10
        static let toggle: CGFloat = 9
        static let badge: CGFloat = 6
    }
}
