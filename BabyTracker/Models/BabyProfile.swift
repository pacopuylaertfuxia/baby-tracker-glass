import Foundation

struct BabyProfile {
    let name: String
    let birthDate: Date

    var ageDescription: String {
        let days = Calendar.current.dateComponents([.day], from: birthDate, to: .now).day ?? 0
        if days < 7 { return "\(days) days old" }
        let weeks = days / 7
        if weeks < 8 { return "\(weeks) weeks old" }
        let months = Calendar.current.dateComponents([.month], from: birthDate, to: .now).month ?? 0
        return "\(months) months old"
    }
}
