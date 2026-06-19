import SwiftUI

/// Mock sounds tab — visual-only sound cards in Moonboon warm aesthetic.
struct SoundsTab: View {
    private let sounds: [(name: String, icon: String)] = [
        ("White Noise", "waveform"),
        ("Rain", "cloud.rain.fill"),
        ("Shush", "mouth.fill"),
        ("Heartbeat", "heart.fill"),
        ("Lullaby", "music.note"),
        ("Ocean", "water.waves"),
        ("Birds", "bird.fill"),
        ("Womb", "circle.circle.fill"),
    ]

    @State private var playingIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 14),
                    GridItem(.flexible(), spacing: 14)
                ], spacing: 14) {
                    ForEach(Array(sounds.enumerated()), id: \.offset) { index, sound in
                        soundCard(name: sound.name, icon: sound.icon, index: index)
                    }
                }
                .padding(16)
                .padding(.bottom, playingIndex != nil ? 80 : 20)
            }

            // Now Playing bar
            if let playing = playingIndex {
                nowPlayingBar(sounds[playing])
            }
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("Sounds")
    }

    private func soundCard(name: String, icon: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                playingIndex = playingIndex == index ? nil : index
            }
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.moonApricot.opacity(0.2))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(.moonClay)
                }

                Text(name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.moonObsidian)

                // Play/stop button
                Image(systemName: playingIndex == index ? "stop.fill" : "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.moonClay)
                    .frame(width: 32, height: 32)
                    .background(.moonApricot.opacity(0.2), in: Circle())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.moonWhite)
                    .shadow(color: .moonBlack.opacity(0.04), radius: 10, y: 4)
            }
        }
        .buttonStyle(.plain)
    }

    private func nowPlayingBar(_ sound: (name: String, icon: String)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: sound.icon)
                .font(.system(size: 18))
                .foregroundStyle(.moonClay)

            Text(sound.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.moonObsidian)

            Spacer()

            // Fake waveform
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.moonClay)
                        .frame(width: 3, height: CGFloat.random(in: 8...20))
                }
            }

            Button {
                withAnimation { playingIndex = nil }
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.moonObsidian)
                    .frame(width: 36, height: 36)
                    .background(.moonApricot.opacity(0.2), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.08), radius: 16, y: -4)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
