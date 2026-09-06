import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: 12) {
            AppIconView()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Token.Radius.icon, style: .continuous))
            Text("JigTail")
                .font(.title2.bold())
                .foregroundStyle(Token.Color.t1)
            Text("Version \(version) (\(build))")
                .font(.caption)
                .foregroundStyle(Token.Color.t2)
            Text("MIT Licensed. A free, native replacement for Jiggler.")
                .font(.caption)
                .foregroundStyle(Token.Color.t3)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 30)
    }
}
