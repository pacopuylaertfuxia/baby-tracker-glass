import Foundation

struct BabyProfile {
    let name: String
    let birthDate: Date

    /// Age-based wake window in minutes
    var wakeWindowMinutes: Double {
        let days = Calendar.current.dateComponents([.day], from: birthDate, to: .now).day ?? 0
        let weeks = days / 7
        let months = days / 30

        if weeks < 8 { return 60 }      // 0-8 weeks
        if months < 4 { return 90 }      // 2-4 months
        if months < 6 { return 120 }     // 4-6 months
        if months < 9 { return 150 }     // 6-9 months
        return 180                        // 9-12 months
    }

    var ageDescription: String {
        let days = Calendar.current.dateComponents([.day], from: birthDate, to: .now).day ?? 0
        if days < 7 { return "\(days) days old" }
        let weeks = days / 7
        if weeks < 8 { return "\(weeks) weeks old" }
        let months = Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0
        return "\(months) months old"
    }
}
