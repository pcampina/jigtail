import AppKit
import SwiftUI

/// The app's own icon, for the popover header and the About pane.
///
/// Source order matters here. `NSApp.applicationIconImage` is the obvious choice and is what
/// PawseKeys uses, but it resolves through LaunchServices and hands back the *generic document
/// icon* — non-zero size, so no simple nil/empty check catches it — whenever that lookup can't
/// resolve the bundle. Reading the compiled `AppIcon.icns` out of the bundle first is
/// deterministic: it's the real artwork on disk, with no cache in the way.
///
/// Note `.fill`, not `.fit`: macOS icon artwork bakes in generous canvas margin (Apple's icon
/// grid, meant for the Dock at large sizes), so fitting the whole canvas into a small header
/// box leaves the glyph looking tiny inside a ring of empty space. Filling and clipping to the
/// rounded frame crops that built-in margin away instead.
struct AppIconView: View {
    var body: some View {
        Group {
            if let icon = Self.bundledIcon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Token.Gradient.brand
            }
        }
    }

    private static let bundledIcon: NSImage? = {
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let image = NSImage(contentsOf: url), image.size != .zero {
            return image
        }
        if let image = NSApp.applicationIconImage, image.size != .zero {
            return image
        }
        if let image = Bundle.main.image(forResource: "AppIcon"), image.size != .zero {
            return image
        }
        return nil
    }()
}
