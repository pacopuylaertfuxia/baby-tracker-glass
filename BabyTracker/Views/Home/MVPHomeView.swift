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

    /// Connected devices. Starts empty (fresh account → empty state);
    /// the user adds one via the "Add device" flow (Pick Device sheet).
    @State private var connectedDevices: [MVPDevice] = []

    /// Genesis event shown at the bottom of Latest events for a fresh account.
    private let profileCreatedDate = Date.now.addingTimeInterval(-180)

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
            MVPTrackSheet()
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
        .onChange(of: sessionManager.activeNap == nil) { _, ended in
            if ended { showNapScreen = false }
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
                // "Add" pill only appears once at least one device is connected.
                // In the empty state the full-width dashed button is the add affordance.
                if !connectedDevices.isEmpty {
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
            }
            .padding(.horizontal, 8)

            if connectedDevices.isEmpty {
                addDeviceButton
            } else {
                deviceCards
            }
        }
    }

    private var addDeviceButton: some View {
        Button {
            showPickDevice = true
        } label: {
            Text("Add device")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.moonOlive)
                .frame(maxWidth: .infinity)
                .frame(height: 106)
                .background(.moonOverlay, in: RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            .moonOlive.opacity(0.35),
                            style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                        )
                )
        }
        .buttonStyle(.plain)
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

            // Fresh account: prompt to log the first event.
            if recentEvents.isEmpty {
                trackFirstEventRow
            } else {
                ForEach(recentEvents) { event in
                    eventRow(event)
                }
            }

            // Genesis event — always present as the account's first entry.
            babyProfileCreatedRow
        }
    }

    private var trackFirstEventRow: some View {
        Button {
            showTrackSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18))
                    .foregroundStyle(.moonClay)
                    .frame(width: 32, height: 32)

                Text("Track your first event")
                    .font(.system(size: 14))
                    .foregroundStyle(.moonOlive)

                Spacer()

                Text("now")
                    .font(.system(size: 12))
                    .foregroundStyle(.moonOlive)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white, in: Capsule())
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            }
            .padding(12)
            .background(.moonOverlay, in: RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
    }

    private var babyProfileCreatedRow: some View {
        HStack(spacing: 8) {
            Image("baby_avatar")
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .clipShape(Circle())

            Text("Baby profile created")
                .font(.system(size: 14))
                .foregroundStyle(.moonOlive)

            Spacer()

            agoChip(for: profileCreatedDate)
        }
        .padding(12)
        .background(.moonOverlay, in: RoundedRectangle(cornerRadius: 24))
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

            Text("(\(Self.clockFormatter.string(from: event.timestamp).lowercased()))")
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
        default:
            timelineStore.logEvent(type)
        }
        dismiss()
    }
}
