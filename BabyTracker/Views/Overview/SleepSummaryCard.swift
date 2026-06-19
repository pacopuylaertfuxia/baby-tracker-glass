import SwiftUI

struct SleepSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's sleep")
                .font(.body.weight(.medium))
                .foregroundStyle(.moonOlive)

            HStack(spacing: 0) {
                statItem(value: "4h 02m", label: "Total", icon: "moon.fill")
                statItem(value: "3", label: "Naps", icon: "bed.double.fill")
                statItem(value: "1h 12m", label: "Longest", icon: "star.fill")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassEffect(.regular.tint(.moonClay), in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(.moonClay)
            Text(value)
                .font(.keplerStat)
                .foregroundStyle(.moonObsidian)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.moonOlive)
        }
        .frame(maxWidth: .infinity)
    }
}
