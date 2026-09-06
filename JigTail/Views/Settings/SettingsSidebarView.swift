import SwiftUI

/// Left-hand navigation list for the settings window — a rounded icon badge plus label per
/// section, with a highlighted background on the active row. Mirrors the macOS System
/// Settings / Alcove-style sidebar rather than a top `TabView` tab bar.
struct SettingsSidebarView: View {
    @Binding var selection: SettingsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsSection.allCases) { section in
                SidebarRow(
                    section: section,
                    isSelected: section == selection
                ) {
                    selection = section
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Token.Color.page)
    }
}

private struct SidebarRow: View {
    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(section.tint)
                    Image(systemName: section.symbolName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 22, height: 22)

                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Token.Color.t1)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(Token.Animation.hoverQuick) { isHovered = hovering }
        }
    }

    /// Selection reads as a raised chip in the family's surface gradient, the same language
    /// the pills and the header's settings button use.
    @ViewBuilder
    private var rowBackground: some View {
        let shape = RoundedRectangle(cornerRadius: Token.Radius.btn, style: .continuous)
        if isSelected {
            shape
                .fill(Token.Gradient.surface)
                .neumorphicOuterShadow(radius: 5)
        } else if isHovered {
            shape.fill(Token.Color.surfaceTop.opacity(0.5))
        } else {
            shape.fill(Color.clear)
        }
    }
}
