import SwiftUI

@Observable
final class DayNightMode {
    var isNightMode: Bool = false

    private let nightStartHour = 20  // 8 PM
    private let nightEndHour = 6     // 6 AM

    init() {
        updateFromTimeOfDay()
    }

    /// Call when a bedtime event is logged
    func enterNightMode() {
        isNightMode = true
    }

    /// Call when a wake event is logged
    func enterDayMode() {
        isNightMode = false
    }

    /// Fallback: use current time of day
    func updateFromTimeOfDay() {
        let hour = Calendar.current.component(.hour, from: .now)
        isNightMode = hour >= nightStartHour || hour < nightEndHour
    }
}
