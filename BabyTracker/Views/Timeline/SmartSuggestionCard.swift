import SwiftUI

/// Contextual "what to do next" card — surfaces the most relevant action
struct SmartSuggestionCard: View {
    @Environment(TimelineStore.self) private var store
    @Environment(SessionManager.self) private var sessionManager

    var body: some View {
        if let suggestion = currentSuggestion {
            HStack(spacing: 12) {
                // Accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(suggestion.accent)
                    .frame(width: 3, height: 36)

                // Icon
                Image(suggestion.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.headline)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.moonObsidian)
                    Text(suggestion.detail)
                        .font(.caption)
                        .foregroundStyle(.moonOlive)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                // Action
                if let actionLabel = suggestion.actionLabel {
                    Button {
                        suggestion.action?()
                    } label: {
                        Text(actionLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.moonObsidian)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                    }
                    .buttonStyle(.glass)
                    .buttonBorderShape(.capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.moonCardBg)
                    .shadow(color: .moonBlack.opacity(0.05), radius: 12, y: 3)
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Suggestion logic

    private struct Suggestion {
        let icon: String
        let headline: String
        let detail: String
        let accent: Color
        let actionLabel: String?
        let action: (() -> Void)?
    }

    private var currentSuggestion: Suggestion? {
        if sessionManager.activeNap != nil { return nil }

        let sleepElapsed = store.timeSince([.nap, .wake])

        // Nap window (awake > 2h) — the one scientifically defensible threshold
        if let sleep = sleepElapsed, sleep > 2 * 3600 {
            let hours = Int(sleep) / 3600
            let mins = (Int(sleep) % 3600) / 60
            return Suggestion(
                icon: "icon_nap",
                headline: "Nap window approaching",
                detail: "Awake \(hours)h \(mins)m — watch for sleepy cues",
                accent: .moonSleep,
                actionLabel: nil,
                action: nil
            )
        }

        return nil
    }
}
