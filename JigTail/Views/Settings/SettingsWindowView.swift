import SwiftUI

struct SettingsWindowView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var selection: SettingsSection = .general

    var body: some View {
        HStack(spacing: 0) {
            SettingsSidebarView(selection: $selection)
                .frame(width: 176)

            Divider()

            VStack(alignment: .leading, spacing: 0) {
                Text(selection.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Token.Color.t1)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)
                    .padding(.bottom, 14)

                ScrollView {
                    pane
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Token.Color.card)
        }
        .frame(width: 600, height: 420)
        .background(Token.Color.page)
        .preferredColorScheme(settings.themeOverride.colorScheme)
    }

    @ViewBuilder
    private var pane: some View {
        switch selection {
        case .general: GeneralSettingsView()
        case .triggers: TriggersSettingsView()
        case .about: AboutView()
        }
    }
}
