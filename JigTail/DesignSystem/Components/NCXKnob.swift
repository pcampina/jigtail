import SwiftUI

/// The centerpiece control, geometry-for-geometry the same dial PawseKeys uses for its lock
/// button: a 148pt ring area, a 128pt raised body, a 100pt concave dish, and a 38pt mark.
/// A tap toggles JigTail's master on/off. Color roles follow the family: brand (orange ->
/// pink) marks selection, green/cyan marks "a jiggle just fired" — the ring and mark blink
/// green three times the instant that happens, then settle back to gray for the next
/// countdown. Green is a signal, not an ambient "currently active" color.
struct NCXKnob<Icon: View>: View {
    var isActive: Bool
    /// The current phase, or nil to show the decorative (untimed) ring.
    var countdown: JiggleCoordinator.Countdown?
    /// True for a brief moment right after a real jiggle fires.
    var pulsing: Bool = false
    @ViewBuilder var icon: () -> Icon
    var action: () -> Void

    @State private var isHovered = false
    @State private var isFlashing = false

    private let ringSize: CGFloat = 148
    private let bodySize: CGFloat = 128
    private let dishSize: CGFloat = 100
    private let iconSize: CGFloat = 38

    var body: some View {
        ZStack {
            CircularTicker(countdown: countdown, isBlinking: isFlashing)
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
                        .overlay(
                            // A mint silhouette of the icon itself, masked by the icon's own
                            // shape so this works regardless of the underlying asset's own
                            // colors — faded in only for the blink.
                            Rectangle()
                                .fill(Token.Color.mint)
                                .mask(icon().frame(width: iconSize, height: iconSize))
                                .opacity(isFlashing ? 1 : 0)
                        )
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
        .onChange(of: pulsing) { newValue in
            if newValue { runFlashSequence() }
        }
    }

    /// Blinks the ring and mark mint 3 times in quick succession — the "a jiggle just
    /// happened" acknowledgement — then leaves them settled back on gray, independent of
    /// how long `pulsing` itself stays true.
    private func runFlashSequence() {
        Task { @MainActor in
            for _ in 0..<3 {
                withAnimation(.easeInOut(duration: 0.09)) { isFlashing = true }
                try? await Task.sleep(nanoseconds: 90_000_000)
                withAnimation(.easeInOut(duration: 0.09)) { isFlashing = false }
                try? await Task.sleep(nanoseconds: 90_000_000)
            }
        }
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
    /// True only for the brief 3-blink acknowledgement right as a jiggle fires — the dashes
    /// are gray the rest of the time, whether counting down to idle or to the next jiggle.
    let isBlinking: Bool

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
                            isBlinking
                                ? AnyShapeStyle(Token.Gradient.ringActive)
                                : AnyShapeStyle(Token.Color.t3),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 5])
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: isBlinking ? Token.Glow.lock : .clear, radius: 3)
                }
                .animation(Token.Animation.ring, value: progress)
                .animation(.easeInOut(duration: 0.09), value: isBlinking)
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
