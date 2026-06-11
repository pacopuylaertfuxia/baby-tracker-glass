import SwiftUI

/// Glass FAB + quick action menu — expands from a floating "+" button
/// Uses GlassEffectContainer + glassEffectID for liquid glass morph animation
struct QuickActionFAB: View {
    let onStartNap: () -> Void
    let onLogDiaper: () -> Void
    let onLogFeed: () -> Void
    let napActive: Bool

    @State private var isExpanded = false
    @Namespace private var fabNS

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            VStack(spacing: 10) {
                if isExpanded {
                    actionButton(image: "icon_nap", label: "Nap", id: "nap", disabled: napActive) {
                        onStartNap()
                        collapse()
                    }
                    actionButton(image: "icon_feed", label: "Feed", id: "feed") {
                        onLogFeed()
                        collapse()
                    }
                    actionButton(image: "icon_diaper", label: "Change", id: "change") {
                        onLogDiaper()
                        collapse()
                    }
                }

                // Main FAB
                Button {
                    withAnimation(.bouncy(duration: 0.35)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2.weight(.semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 54, height: 54)
                }
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .tint(.moonClay)
                .shadow(color: .moonClay.opacity(0.35), radius: 12, y: 4)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                .glassEffectID("fab-main", in: fabNS)
            }
        }
    }

    private func actionButton(image: String, label: String, id: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                Text(label)
                    .font(.system(size: 15, weight: .medium))
            }
            .frame(width: 120, height: 46)
        }
        .buttonStyle(.glass)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1)
        .glassEffectID("fab-\(id)", in: fabNS)
        .transition(.identity)
    }

    private func collapse() {
        withAnimation(.bouncy(duration: 0.3)) {
            isExpanded = false
        }
    }
}
