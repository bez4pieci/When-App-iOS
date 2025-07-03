import PhosphorSwift
import SwiftUI

struct MainHeader: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station?
    let departuresViewModel: DeparturesViewModel
    let onSettingsButtonTap: () -> Void

    private let buttonSize = 48.0
    private let sideMargin = 16.0
    private let iconSize = 24.0

    // Animation state for live icon
    @State private var liveIconIndex: Int = 0
    @State private var liveIconTimer: Timer? = nil
    private let liveIcons: [(Color) -> AnyView] = [
        { color in AnyView(Ph.dot.regular.color(color)) },
        { color in AnyView(Ph.dotOutline.regular.color(color)) },
        // { color in AnyView(Ph.circle.regular.color(color)) },
        // { color in AnyView(Ph.dotOutline.regular.color(color)) },
    ]
    private let liveIconAnimationDuration: Double = 2.0  // seconds

    private var isLiveActivityActive: Bool {
        if let station = station {
            return liveActivityManager.liveActivityStatus(for: station.id) == .loading
                || liveActivityManager.liveActivityStatus(for: station.id) == .active
        }
        return false
    }

    var body: some View {
        HStack(spacing: 12) {
            if station != nil {
                liveToggleButton
                Spacer()
                settingsButton
            }
        }
        .onChange(of: isLiveActivityActive) { _, isActive in
            handleLiveIconAnimation(isActive: isActive)
        }
        .onAppear {
            handleLiveIconAnimation(isActive: isLiveActivityActive)
        }
        .onDisappear {
            liveIconTimer?.invalidate()
            liveIconTimer = nil
        }
    }

    private func handleLiveIconAnimation(isActive: Bool) {
        liveIconTimer?.invalidate()
        if isActive {
            liveIconIndex = 0
            liveIconTimer = Timer.scheduledTimer(
                withTimeInterval: liveIconAnimationDuration / Double(liveIcons.count), repeats: true
            ) { _ in
                withAnimation(
                    .easeInOut(duration: liveIconAnimationDuration / Double(liveIcons.count))
                ) {
                    liveIconIndex = (liveIconIndex + 1) % liveIcons.count
                }
            }
        } else {
            liveIconTimer = nil
        }
    }

    private var settingsButton: some View {
        Button(action: onSettingsButtonTap) {
            Ph.faders.regular.color(Color.dDefault)
                .frame(width: iconSize, height: iconSize)
                .padding(12)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.dBackground)
        .clipShape(Circle())
        .frame(width: buttonSize, height: buttonSize)
        .padding(.top, safeAreaInsets.top)
        .padding(.trailing, sideMargin)
    }

    private var liveToggleButton: some View {
        Group {
            Button(action: {
                toggleLiveActivity()
            }) {
                HStack(spacing: 8) {
                    Text("Live")
                        .font(Font.dSmall)
                        .foregroundColor(Color.dDefault)

                    if isLiveActivityActive {
                        ZStack {
                            ForEach(0..<liveIcons.count, id: \.self) { idx in
                                liveIcons[idx](Color.dDefault)
                                    .frame(width: iconSize, height: iconSize)
                                    .opacity(liveIconIndex == idx ? 1.0 : 0.0)
                                    .animation(
                                        .easeInOut(
                                            duration: liveIconAnimationDuration
                                                / Double(liveIcons.count)), value: liveIconIndex
                                    )
                            }
                        }
                    }
                }
                .frame(height: buttonSize)
                .padding(.leading, 16)
                .padding(.trailing, isLiveActivityActive ? 12 : 16)
            }
            .buttonStyle(.plain)
            .background(Color.dBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppConfig.cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppConfig.cornerRadius))
            .padding(.top, safeAreaInsets.top)
            .padding(.leading, sideMargin)
        }
    }

    private func toggleLiveActivity() {
        guard let station = station else {
            return
        }

        if isLiveActivityActive {
            Task {
                await liveActivityManager.stopLiveActivity(for: station.id)
            }
        } else {
            Task {
                await liveActivityManager.startLiveActivity(station: station) {
                    await departuresViewModel.loadDepartures(for: station)
                    return departuresViewModel.filteredDepartures(for: station)
                }
            }
        }
    }
}

#Preview {
    MainHeader(
        station: Station(
            id: "900058101",
            name: "S Südkreuz Bhf (Berlin)",
            latitude: 52.475501,
            longitude: 13.365548,
            products: [.suburban, .bus, .regional, .express],
        ),
        departuresViewModel: DeparturesViewModel(),
        onSettingsButtonTap: {}
    )
    .environmentObject(LiveActivityManager())
}
