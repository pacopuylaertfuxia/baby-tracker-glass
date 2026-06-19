import SwiftUI

/// Profile header — avatar, name, age, today's date
struct BabyProfileHeader: View {
    let baby: BabyProfile

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Image("baby_avatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.moonApricot, lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(baby.name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.moonObsidian)

                Text(baby.ageDescription)
                    .font(.caption)
                    .foregroundStyle(.moonOlive)
            }

            Spacer()

            // Today
            VStack(alignment: .trailing, spacing: 1) {
                Text(Date.now.formatted(.dateTime.weekday(.wide)))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.moonClay)
                Text(Date.now.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.caption2)
                    .foregroundStyle(.moonOlive)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
