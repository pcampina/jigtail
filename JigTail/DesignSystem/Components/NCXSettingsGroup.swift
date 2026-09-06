import SwiftUI

/// A rounded, grouped list of settings rows — mirrors the macOS System Settings /
/// Alcove-style "card of rows with hairline dividers" pattern, built on the DS's
/// existing raised-neumorphic surface instead of a native `Form`/`List`.
struct NCXSettingsGroup<Content: View>: View {
    var title: String? = nil
    @ViewBuilder var rows: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Token.Color.t3)
                    .padding(.leading, 4)
            }

            VStack(spacing: 0) {
                rows()
            }
            .background(
                RoundedRectangle(cornerRadius: Token.Radius.card, style: .continuous)
                    .fill(Token.Gradient.surface)
            )
            .neumorphicOuterShadow()
        }
    }
}

/// One row inside an `NCXSettingsGroup`: a leading title/subtitle and trailing control,
/// separated from the next row by a hairline divider (omit via `showDivider` on the last row).
struct NCXSettingsRow<Trailing: View>: View {
    var title: String
    var subtitle: String? = nil
    var showDivider: Bool = true
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundStyle(Token.Color.t1)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(Token.Color.t3)
                    }
                }
                Spacer(minLength: 8)
                trailing()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            if showDivider {
                Divider()
                    .padding(.leading, 14)
            }
        }
    }
}
