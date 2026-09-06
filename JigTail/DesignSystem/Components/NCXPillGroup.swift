import SwiftUI

/// The family's preset row — PawseKeys' auto-unlock timer pills (1m/2m/5m/10m/30m), reused
/// here for the idle threshold. Rounded rectangles at a fixed 30pt height, not capsules:
/// selected fills with the brand gradient and casts a brand glow, unselected sits on the
/// pill-inactive gradient with a raised neumorphic shadow pair.
struct NCXPillGroup<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    var label: (Value) -> String

    @State private var hovered: Value?

    var body: some View {
        HStack(spacing: 5) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                let isHovered = hovered == option

                Button {
                    withAnimation(Token.Animation.select) { selection = option }
                } label: {
                    Text(label(option))
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(Token.Color.t2))
                        .background(pillBackground(isSelected: isSelected))
                        .clipShape(RoundedRectangle(cornerRadius: Token.Radius.btn, style: .continuous))
                        .scaleEffect(isHovered && !isSelected ? 1.06 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(Token.Animation.hoverQuick) {
                        hovered = hovering ? option : nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func pillBackground(isSelected: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Token.Radius.btn, style: .continuous)
        if isSelected {
            shape
                .fill(Token.Gradient.brand)
                .shadow(color: Token.Glow.brand, radius: 5, y: 3)
        } else {
            shape
                .fill(Token.Gradient.pillInactive)
                .shadow(color: Token.Color.outerDarkShadow.opacity(0.5), radius: 3, x: 3, y: 3)
                .shadow(color: Token.Color.outerLightShadow, radius: 2.5, x: -2, y: -2)
        }
    }
}
