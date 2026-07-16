import SwiftUI

/// The "MVP" home screen from the Moonboon product vision (Figma node 989:4711).
/// Header with avatar + wordmark, Devices cards, Latest events feed,
/// and a floating bottom bar with the active-nap pill and a + track button.
struct MVPHomeView: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @State private var showTrackSheet = false
    @State private var showNapScreen = false
    @State private var showPickDevice = false
    @State private var showBedtimeScreen = false
    @State private var bedtimeStartsAwake = false
    @State private var pendingBedtimeScreen = false

    @State private var connectedDevices: [MVPDevice] = [.cradleBouncers]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.moonCreme.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    devicesSection
                    latestEventsSection
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
            }

            bottomBar
        }
        .sheet(isPresented: $showTrackSheet) {
            MVPTrackSheet { startAwake in
                bedtimeStartsAwake = startAwake
                pendingBedtimeScreen = true
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .presentationBackground(.moonCreme)
        }
        .sheet(isPresented: $showPickDevice) {
            MVPPickDeviceSheet { connect(.cradleBouncers) }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.moonCreme)
        }
        .fullScreenCover(isPresented: $showNapScreen) {
            SleepTrackingScreen(mode: .nap)
        }
        .fullScreenCover(isPresented: $showBedtimeScreen) {
            SleepTrackingScreen(mode: .bedtime, startAwake: bedtimeStartsAwake)
        }
        .onChange(of: showTrackSheet) { _, shown in
            // Present the bedtime screen only after the track sheet fully dismisses.
            if !shown && pendingBedtimeScreen {
                pendingBedtimeScreen = false
                showBedtimeScreen = true
            }
        }
        .onChange(of: sessionManager.activeNap == nil) { _, ended in
            if ended { showNapScreen = false }
        }
        .onChange(of: sessionManager.activeBedtime == nil) { _, ended in
            if ended { showBedtimeScreen = false }
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("moonboon")
                .font(.kepler(28))
                .foregroundStyle(.moonObsidian)
                .frame(maxWidth: .infinity)

            HStack {
                Image("baby_avatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(Circle())
                Spacer()
            }
        }
    }

    // MARK: - Devices

    private var devicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Devices")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.moonOlive)
                Spacer()
                Button {
                    showPickDevice = true
                } label: {
                    Text("Add")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.moonBlack)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(.moonApricot, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)

            deviceCards
        }
    }

    @ViewBuilder
    private var deviceCards: some View {
        if connectedDevices.count == 1 {
            deviceCard(connectedDevices[0], fullWidth: true)
        } else {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                ForEach(connectedDevices) { device in
                    deviceCard(device, fullWidth: false)
                }
            }
        }
    }

    private func connect(_ device: MVPDevice) {
        guard !connectedDevices.contains(where: { $0.id == device.id }) else { return }
        withAnimation(.spring(duration: 0.35)) {
            connectedDevices.append(device)
        }
    }

    private func deviceCard(_ device: MVPDevice, fullWidth: Bool) -> some View {
        let size = fullWidth ? device.fullWidthImageSize : device.imageSize
        let offset = fullWidth ? device.fullWidthImageOffset : device.imageOffset
        return ZStack(alignment: .topLeading) {
            Image(device.image)
                .resizable()
                .scaledToFit()
                .frame(height: size.height)
                .offset(offset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 0) {
                Text(device.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.moonOlive)
                HStack(spacing: 4) {
                    Circle()
                        .fill(device.isActive ? Color.moonSuccess : Color.moonOlive.opacity(0.4))
                        .frame(width: 8, height: 8)
                    Text(device.status)
                        .font(.system(size: 12))
                        .foregroundStyle(.moonOlive)
                }
                Spacer()
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 106)
        .background(.moonOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Latest events

    private var latestEventsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest events")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.moonOlive)
                .padding(.horizontal, 8)

            ForEach(recentEvents) { event in
                eventRow(event)
            }
        }
    }

    private var recentEvents: [TimelineEvent] {
        Array(timelineStore.events.sorted { $0.timestamp > $1.timestamp }.prefix(8))
    }

    private func eventRow(_ event: TimelineEvent) -> some View {
        HStack(spacing: 8) {
            eventIcon(event.type)

            Text(event.type.displayName)
                .font(.system(size: 14))
                .foregroundStyle(.moonOlive)

            Text("(\(Self.timeText(for: event)))")
                .font(.system(size: 12))
                .foregroundStyle(.moonOlive.opacity(0.7))

            Spacer()

            agoChip(for: event.timestamp)
        }
        .padding(12)
        .background(.moonOverlay, in: RoundedRectangle(cornerRadius: 24))
    }

    private func eventIcon(_ type: TimelineEvent.EventType) -> some View {
        Group {
            if let imageName = type.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: type.sfSymbol)
                    .foregroundStyle(.moonClay)
            }
        }
        .frame(width: 32, height: 32)
    }

    private func agoChip(for date: Date) -> some View {
        HStack(spacing: 1) {
            Text(Self.agoValue(since: date))
                .font(.system(size: 12))
                .foregroundStyle(.moonOlive)
            Text("ago")
                .font(.system(size: 12))
                .foregroundStyle(.moonOlive.opacity(0.7))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(.white, in: Capsule())
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 8) {
            if sessionManager.activeNap != nil {
                nappingPill
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if sessionManager.activeBedtime != nil {
                sleepingPill
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Spacer()
            }

            Button {
                showTrackSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.moonObsidian)
                    .frame(width: 60, height: 59)
            }
            .buttonStyle(.glass)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background(alignment: .bottom) {
            LinearGradient(
                colors: [.moonCreme.opacity(0), .moonCreme],
                startPoint: .top,
                endPoint: .center
            )
            .frame(height: 159)
            .ignoresSafeArea(edges: .bottom)
            .allowsHitTesting(false)
        }
        .animation(.spring(duration: 0.35), value: sessionManager.activeNap != nil)
        .animation(.spring(duration: 0.35), value: sessionManager.activeBedtime != nil)
    }

    private var sleepingPill: some View {
        Button {
            bedtimeStartsAwake = false
            showBedtimeScreen = true
        } label: {
            HStack(spacing: 8) {
                Image("icon_bedtime")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Sleeping")
                        .font(.system(size: 12))
                        .foregroundStyle(.moonObsidian)
                    if let bedtime = sessionManager.activeBedtime {
                        Text(bedtime.startTime, style: .timer)
                            .font(.system(size: 14))
                            .monospacedDigit()
                            .foregroundStyle(.moonClay)
                    }
                }
                Spacer()
            }
            .padding(9)
            .frame(height: 59)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .clipShape(Capsule())
    }

    private var nappingPill: some View {
        Button {
            showNapScreen = true
        } label: {
            HStack(spacing: 8) {
                Image("icon_nap")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Napping")
                        .font(.system(size: 12))
                        .foregroundStyle(.moonObsidian)
                    if let nap = sessionManager.activeNap {
                        Text(nap.startTime, style: .timer)
                            .font(.system(size: 14))
                            .monospacedDigit()
                            .foregroundStyle(.moonClay)
                    }
                }
                Spacer()
            }
            .padding(9)
            .frame(height: 59)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .clipShape(Capsule())
    }

    // MARK: - Formatting

    private static let clockFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    /// Night wakings with a known awake duration show the full window, e.g. "1:30 – 1:38 am".
    private static func timeText(for event: TimelineEvent) -> String {
        let start = clockFormatter.string(from: event.timestamp).lowercased()
        guard event.type == .nightWaking, let duration = event.wakeDuration, duration > 0 else {
            return start
        }
        let end = clockFormatter.string(from: event.timestamp.addingTimeInterval(duration)).lowercased()
        return "\(start) – \(end)"
    }

    private static func agoValue(since date: Date) -> String {
        let interval = Date.now.timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 60 { return "\(max(minutes, 1))m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}

// MARK: - Device model

struct MVPDevice: Identifiable {
    let id: String
    let name: String
    let status: String
    let image: String
    let isActive: Bool
    /// Image sizing when shown in a half-width (two-up) card.
    let imageSize: CGSize
    let imageOffset: CGSize
    /// Image sizing when shown as a single full-width card.
    let fullWidthImageSize: CGSize
    let fullWidthImageOffset: CGSize

    static let cradleBouncers = MVPDevice(
        id: "cradle-bouncers",
        name: "Motor",
        status: "Off",
        image: "mvp_motor",
        isActive: false,
        imageSize: CGSize(width: 210, height: 263),
        imageOffset: CGSize(width: 31, height: -84),
        fullWidthImageSize: CGSize(width: 200, height: 170),
        fullWidthImageOffset: CGSize(width: 6, height: -18)
    )
}

// MARK: - Pick Device sheet (add-device flow)

struct MVPPickDeviceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Pick Device")
                .font(.kepler(28))
                .foregroundStyle(.moonObsidian)
                .padding(.top, 28)

            deviceCard

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("mvp_motor")
                .resizable()
                .scaledToFit()
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get started")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.moonClay)
                    Text("Cradle Bouncers")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.moonOlive)
                }
                Spacer()
                Button {
                    onConnect()
                    dismiss()
                } label: {
                    Text("Connect")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.moonBlack)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(.moonApricot, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(.moonOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Track sheet (MVP design: Kepler title + event rows)

struct MVPTrackSheet: View {
    @Environment(SessionManager.self) private var sessionManager
    @Environment(TimelineStore.self) private var timelineStore
    @Environment(\.dismiss) private var dismiss

    /// Called after dismissal to open the bedtime screen; `startAwake` = true for a night waking.
    let onBedtimeScreen: (_ startAwake: Bool) -> Void

    private let types: [TimelineEvent.EventType] = [.nap, .wake, .bedtime, .nightWaking]

    var body: some View {
        VStack(spacing: 12) {
            Text("Track")
                .font(.kepler(32))
                .foregroundStyle(.moonObsidian)
                .padding(.top, 32)

            VStack(spacing: 8) {
                ForEach(types, id: \.rawValue) { type in
                    Button {
                        track(type)
                    } label: {
                        HStack(spacing: 8) {
                            Group {
                                if let imageName = type.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                            .frame(width: 32, height: 32)

                            Text(type.displayName)
                                .font(.system(size: 14))
                                .foregroundStyle(.moonOlive)
                            Spacer()
                        }
                        .padding(12)
                        .background(.moonOverlay, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                    .disabled(type == .nap && sessionManager.activeNap != nil)
                    .opacity(type == .nap && sessionManager.activeNap != nil ? 0.5 : 1)
                }
            }
            .padding(.horizontal, 16)

            Spacer()
        }
    }

    private func track(_ type: TimelineEvent.EventType) {
        switch type {
        case .nap:
            sessionManager.startNap()
        case .bedtime:
            sessionManager.startBedtime()
            timelineStore.logBedtime()
            onBedtimeScreen(false)
        case .nightWaking:
            // Night waking lives inside the bedtime flow: start bedtime if needed
            // and open the bedtime screen in the Awake state. The event is logged
            // on "Back to sleep" with the awake time window.
            if sessionManager.activeBedtime == nil {
                sessionManager.startBedtime()
                timelineStore.logBedtime()
            }
            onBedtimeScreen(true)
        default:
            timelineStore.logEvent(type)
        }
        dismiss()
    }
}
