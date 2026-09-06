import SwiftUI

/// The centerpiece control, geometry-for-geometry the same dial PawseKeys uses for its lock
/// button: a 148pt ring area, a 128pt raised body, a 100pt concave dish, and a 38pt mark.
/// A tap toggles JigTail's master on/off. Color roles follow the family: brand (orange ->
/// pink) marks selection, green/cyan marks "active right now" — so the ring and mark go
/// green while jiggling, exactly as PawseKeys goes green when locked.
struct NCXKnob<Icon: View>: View {
    var isActive: Bool
    /// The current phase, or nil to show the decorative (untimed) ring.
    var countdown: JiggleCoordinator.Countdown?
    /// True for a brief moment right after a real jiggle fires.
    var pulsing: Bool = false
    @ViewBuilder var icon: () -> Icon
    var action: () -> Void

    @State private var isHovered = false

    private let ringSize: CGFloat = 148
    private let bodySize: CGFloat = 128
    private let dishSize: CGFloat = 100
    private let iconSize: CGFloat = 38

    var body: some View {
        ZStack {
            CircularTicker(countdown: countdown, isActive: isActive)
                .frame(width: ringSize, height: ringSize)

            // Ambient glow under the body, tinted by state.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [isActive ? Token.Color.mint : Token.Color.red, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 55
                    )
                )
                .frame(width: 110, height: 110)
                .blur(radius: 22)
                .opacity(isActive ? 0.18 : 0.12)

            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Token.Gradient.surface)
                        .frame(width: bodySize, height: bodySize)
                        .shadow(color: Token.Color.outerDarkShadow, radius: 11, x: 8, y: 10)
                        .shadow(color: Token.Color.outerLightShadow, radius: 8, x: -5, y: -5)

                    Circle()
                        .fill(Token.Gradient.dish)
                        .frame(width: dishSize, height: dishSize)
                        .neumorphicInnerShadow()
                        .shadow(color: pulsing ? Token.Glow.lock : .clear, radius: pulsing ? 12 : 0)
                        .scaleEffect(pulsing ? 1.04 : 1.0)

                    icon()
                        .frame(width: iconSize, height: iconSize)
                }
            }
            .buttonStyle(NeumorphicButtonStyle())
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .onHover { hovering in
                withAnimation(Token.Animation.hover) { isHovered = hovering }
            }
        }
        .frame(width: ringSize, height: ringSize)
        .animation(Token.Animation.press, value: isActive)
        .animation(.easeOut(duration: 0.25), value: pulsing)
    }
}

/// The ring. When a phase is running it's a dashed arc that fills segment by segment,
/// reaching a complete circle exactly at the deadline — for JigTail that's the instant a
/// jiggle fires. With no phase it falls back to the family's decorative dashed ring.
///
/// Progress is recomputed from `(deadline, totalDuration, now)` on each one-second tick and
/// lerped between ticks, rather than kicked off once into local `@State`. That distinction
/// matters: local state is thrown away when the popover is hidden and rebuilt, which is what
/// made the ring restart from scratch on every reopen.
private struct CircularTicker: View {
    let countdown: JiggleCoordinator.Countdown?
    let isActive: Bool

    var body: some View {
        if let countdown {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let progress = max(0.001, countdown.elapsedProgress(at: context.date))
                ZStack {
                    Circle()
                        .stroke(Token.Color.line.opacity(0.5), lineWidth: 2.5)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            isActive
                                ? AnyShapeStyle(Token.Gradient.ringActive)
                                : AnyShapeStyle(Token.Color.t3),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 5])
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: isActive ? Token.Glow.lock : .clear, radius: 3)
                }
                .animation(Token.Animation.ring, value: progress)
            }
        } else {
            Circle()
                .stroke(
                    Token.Color.line.opacity(0.5),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 6])
                )
        }
    }
}

/// PawseKeys' `NeumorphicButtonStyle`.
struct NeumorphicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(Token.Animation.press, value: configuration.isPressed)
    }
}
