import SwiftUI

extension Font {
    static func kepler(_ size: CGFloat) -> Font {
        .custom("KeplerStd-Disp", size: size)
    }

    static var keplerLargeTitle: Font { .kepler(42) }
    static var keplerTitle: Font { .kepler(32) }
    static var keplerHeadline: Font { .kepler(28) }
    static var keplerTimer: Font { .kepler(56) }
    static var keplerStat: Font { .kepler(24) }
}

// Convenience for time pill styling
extension Text {
    func timePill() -> some View {
        self
            .font(.system(size: 12, weight: .regular, design: .default))
            .monospacedDigit()
            .foregroundStyle(.moonOlive)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.white, in: Capsule())
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}
