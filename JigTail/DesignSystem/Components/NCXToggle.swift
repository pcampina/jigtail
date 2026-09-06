import SwiftUI

/// PawseKeys' `NeumorphicToggle`: a 34x18 rounded-rectangle track (not a capsule) that fills
/// with the brand gradient and casts a brand glow when on, sits on the dish gradient when
/// off, and carries a plain white 14pt knob.
struct NCXToggle: View {
    @Binding var isOn: Bool

    @State private var isHovered = false

    var body: some View {
        Button {
            withAnimation(Token.Animation.select) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: Token.Radius.toggle, style: .continuous)
                    .fill(isOn ? AnyShapeStyle(Token.Gradient.brand) : AnyShapeStyle(Token.Gradient.dish))
                    .frame(width: 34, height: 18)
                    .shadow(color: isOn ? Token.Glow.brand : .clear, radius: 3, y: 2)

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.22), radius: 2, y: 1)
                    .padding(.horizontal, 2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.06 : 1.0)
        .onHover { hovering in
            withAnimation(Token.Animation.hoverQuick) { isHovered = hovering }
        }
    }
}
