import SwiftUI

struct DevicesTab: View {
    @Environment(SessionManager.self) private var sessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                deviceCard(
                    emoji: "🌙",
                    name: "Moonboon Motor",
                    subtitle: motorSubtitle,
                    isActive: sessionManager.activeMotor != nil,
                    onTap: {
                        if sessionManager.activeMotor != nil {
                            sessionManager.stopMotor()
                        } else {
                            sessionManager.startMotor()
                        }
                    }
                )

                deviceCard(
                    emoji: "📹",
                    name: "Baby Monitor",
                    subtitle: monitorSubtitle,
                    isActive: sessionManager.activeMonitor != nil,
                    onTap: {
                        if sessionManager.activeMonitor != nil {
                            sessionManager.stopMonitor()
                        } else {
                            sessionManager.startMonitor()
                        }
                    }
                )

                Spacer(minLength: 120)
            }
            .padding(.top, 8)
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("Devices")
    }

    private var motorSubtitle: String {
        guard let motor = sessionManager.activeMotor,
              let rem = sessionManager.remaining(for: motor) else {
            return "Sleep program · 44 min"
        }
        return "\(formatDuration(rem)) remaining"
    }

    private var monitorSubtitle: String {
        guard let monitor = sessionManager.activeMonitor else {
            return "Video & audio streaming"
        }
        return "Streaming · \(formatDuration(sessionManager.elapsed(for: monitor)))"
    }

    private func deviceCard(emoji: String, name: String, subtitle: String, isActive: Bool, onTap: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.moonApricot)
                        .frame(width: 48, height: 48)
                    Text(emoji)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                Spacer()

                if isActive {
                    Circle()
                        .fill(.moonSuccess)
                        .frame(width: 10, height: 10)
                        .shadow(color: .moonSuccess.opacity(0.5), radius: 4)
                }
            }

            if isActive {
                Button(action: onTap) {
                    Text("Stop")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glassProminent)
                .tint(.moonClay)
            } else {
                Button(action: onTap) {
                    Text(name.contains("Motor") ? "Start program" : "Start streaming")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.glass)
            }
        }
        .padding(20)
        .background(.moonCardBg, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16)
    }
}
