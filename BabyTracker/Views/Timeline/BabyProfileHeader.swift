import SwiftUI

/// Profile header — real baby photo from Figma + name + age
struct BabyProfileHeader: View {
    let baby: BabyProfile

    var body: some View {
        HStack(spacing: 12) {
            // Real baby avatar from Figma
            Image("baby_avatar")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 53, height: 53)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(.moonApricot, lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 2) {
                Text(baby.name)
                    .font(.title2.weight(.semibold))  // 22pt
                    .foregroundStyle(.moonObsidian)

                Text(baby.ageDescription)
                    .font(.subheadline)  // 15pt
                    .foregroundStyle(.moonOlive)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
