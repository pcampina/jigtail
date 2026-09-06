import SwiftUI

/// A surface with the family's raised or inset treatment.
struct NCXCard<Content: View>: View {
    var variant: NeumorphicVariant = .raised
    var cornerRadius: CGFloat = Token.Radius.card
    @ViewBuilder var content: () -> Content

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        content()
            .padding(13)
            .background(shape.fill(variant == .raised ? Token.Gradient.surface : Token.Gradient.dish))
            .neumorphic(variant)
    }
}

/// PawseKeys' section divider: a hairline that fades out at both ends rather than running
/// edge to edge, inset by the same 20pt as the content around it.
struct NCXDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Token.Color.line, Token.Color.line, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 20)
    }
}
