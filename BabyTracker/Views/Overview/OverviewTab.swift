import SwiftUI

struct OverviewTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SleepSummaryCard()
                WeeklyChart()

                // Growth card with glass effect
                VStack(alignment: .leading, spacing: 16) {
                    Text("Growth")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.moonOlive)

                    HStack(spacing: 0) {
                        growthItem(value: "4.2 kg", label: "Weight", trend: "+120g")
                        growthItem(value: "54 cm", label: "Height", trend: "+1.5cm")
                        growthItem(value: "37 cm", label: "Head", trend: "+0.5cm")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.moonWhite, in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 16)

                Spacer(minLength: 120)
            }
            .padding(.top, 8)
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("Overview")
    }

    private func growthItem(value: String, label: String, trend: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.kepler(20))
                .foregroundStyle(.primary)
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text(trend)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.moonSuccess)
        }
        .frame(maxWidth: .infinity)
    }
}
