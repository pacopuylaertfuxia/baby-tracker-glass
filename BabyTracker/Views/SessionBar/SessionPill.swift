import SwiftUI

// Utility — shared time formatting
func formatDuration(_ interval: TimeInterval) -> String {
    let total = Int(max(0, interval))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
}
