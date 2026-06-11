import Foundation

@Observable
final class BabyStore {
    let baby: BabyProfile

    init() {
        let cal = Calendar.current
        let birthDate = cal.date(byAdding: .day, value: -35, to: .now)!
        baby = BabyProfile(name: "Olivia", birthDate: birthDate)
    }
}
