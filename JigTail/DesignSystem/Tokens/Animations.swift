import SwiftUI

extension Token {
    /// The family's motion vocabulary, taken from PawseKeys' call sites so both apps feel
    /// identical under the finger.
    enum Animation {
        /// Button press (`NeumorphicButtonStyle`) and pill/toggle selection.
        static let press = SwiftUI.Animation.spring(response: 0.25, dampingFraction: 0.7)
        static let select = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)

        /// Hover: slightly quicker on the small controls than on the big knob.
        static let hover = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let hoverQuick = SwiftUI.Animation.easeInOut(duration: 0.12)

        /// Section show/hide.
        static let section = SwiftUI.Animation.easeInOut(duration: 0.2)

        /// The progress ring lerps between one-second model ticks — just under a second, so
        /// each segment lands as the next tick arrives instead of stuttering.
        static let ring = SwiftUI.Animation.linear(duration: 0.95)

        static let `default` = press
    }
}
