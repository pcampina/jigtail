import SwiftUI

/// The status-bar icon itself, live SwiftUI content (not a static bitmap) so it can wag
/// while actively jiggling: faint mark while off, dimmed while armed and waiting for
/// idle, full-brightness wagging cursor+tail while active.
struct MenuBarLabelView: View {
    @EnvironmentObject private var coordinator: JiggleCoordinator

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                switch coordinator.state {
                case .off:
                    Image("MenuBarIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .opacity(0.25)
                case .idleWaiting:
                    Image("MenuBarIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                        .opacity(0.4)
                case .activeJiggling:
                    Image("MenuBarIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
            }

            if coordinator.hasRecentJiggle {
                Circle()
                    .fill(Token.Color.mint)
                    .frame(width: 6, height: 6)
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.35), lineWidth: 1))
                    .offset(x: 2, y: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 18, height: 18)
        .animation(.spring(response: 0.24, dampingFraction: 0.72), value: coordinator.hasRecentJiggle)
    }
}
