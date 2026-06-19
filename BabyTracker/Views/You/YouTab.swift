import SwiftUI

/// Profile & settings tab — baby profile header, device cards, settings rows.
struct YouTab: View {
    @Environment(BabyStore.self) private var babyStore
    @Environment(SessionManager.self) private var sessionManager

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Baby profile header
                BabyProfileHeader(baby: babyStore.baby)
                    .padding(.top, 4)

                // Devices section
                devicesSection

                // Settings section
                settingsSection

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(.moonCreme)
        .scrollContentBackground(.hidden)
        .navigationTitle("You")
    }

    // MARK: - Devices

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Devices", icon: "sensor.fill")

            VStack(spacing: 10) {
                deviceRow(
                    emoji: "🌙",
                    name: "Moonboon Motor",
                    status: sessionManager.activeMotor != nil ? "Active" : "Standby",
                    isActive: sessionManager.activeMotor != nil
                )

                deviceRow(
                    emoji: "📹",
                    name: "Baby Monitor",
                    status: sessionManager.activeMonitor != nil ? "Streaming" : "Standby",
                    isActive: sessionManager.activeMonitor != nil
                )
            }
            .padding(.horizontal, 16)
        }
    }

    private func deviceRow(emoji: String, name: String, status: String, isActive: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.moonApricot.opacity(0.2))
                    .frame(width: 44, height: 44)
                Text(emoji)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.moonObsidian)
                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? .moonSuccess : .moonOlive)
            }

            Spacer()

            if isActive {
                Circle()
                    .fill(.moonSuccess)
                    .frame(width: 8, height: 8)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.moonStone)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.moonWhite)
                .shadow(color: .moonBlack.opacity(0.04), radius: 8, y: 3)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Settings", icon: "gearshape.fill")

            VStack(spacing: 2) {
                settingsRow(icon: "bell.fill", title: "Notifications", detail: "On")
                settingsRow(icon: "ruler.fill", title: "Units", detail: "Metric")
                settingsRow(icon: "square.and.arrow.up.fill", title: "Export data", detail: "")
                settingsRow(icon: "questionmark.circle.fill", title: "Help & feedback", detail: "")
            }
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.moonWhite)
                    .shadow(color: .moonBlack.opacity(0.04), radius: 8, y: 3)
            }
            .padding(.horizontal, 16)
        }
    }

    private func settingsRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.moonClay)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.moonObsidian)

            Spacer()

            if !detail.isEmpty {
                Text(detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.moonOlive)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.moonStone)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.moonClay)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.moonClay)
                .textCase(.uppercase)
                .tracking(0.6)
        }
        .padding(.horizontal, 20)
    }
}
