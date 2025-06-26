import PhosphorSwift
import SwiftUI

struct MainHeader: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    @EnvironmentObject private var liveActivityManager: LiveActivityManager
    let station: Station?
    let departuresViewModel: DeparturesViewModel
    let onGearButtonTap: () -> Void

    private let buttonSize = 48.0
    private let sideMargin = 16.0
    private let cornerRadius = 24.0

    // Animation state for live icon
    @State private var liveIconIndex: Int = 0
    @State private var liveIconTimer: Timer? = nil
    private let liveIcons: [(Color) -> AnyView] = [
        { color in AnyView(Ph.dot.regular.color(color)) },
        { color in AnyView(Ph.dotOutline.regular.color(color)) },
        // { color in AnyView(Ph.circle.regular.color(color)) },
        // { color in AnyView(Ph.dotOutline.regular.color(color)) },
    ]
    private let liveIconAnimationDuration: Double = 1.5  // seconds

    private func isLiveActive(for station: Station) -> Bool {
        liveActivityManager.isLiveActivityActive(for: station.id)
    }

    var body: some View {
        HStack(spacing: 12) {
            liveToggleButton
            Spacer()
            gearButton
        }
        .onChange(of: isLiveActiveForCurrentStation) { _, isActive in
            handleLiveIconAnimation(isActive: isActive)
        }
        .onAppear {
            handleLiveIconAnimation(isActive: isLiveActiveForCurrentStation)
        }
        .onDisappear {
            liveIconTimer?.invalidate()
            liveIconTimer = nil
        }
    }

    private var isLiveActiveForCurrentStation: Bool {
        if let station = station {
            return self.isLiveActive(for: station)
        }
        return false
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

    private var gearButton: some View {
        Button(action: onGearButtonTap) {
            Ph.faders.regular.color(Color.dDefault)
                .frame(width: 24, height: 24)
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
            if let station = station {
                Button(action: {
                    toggleLiveActivity(for: station)
                }) {
                    HStack(spacing: 8) {
                        Text("Live")
                            .font(Font.dSmall)
                            .foregroundColor(Color.dDefault)
                        if isLiveActiveForCurrentStation {
                            ZStack {
                                ForEach(0..<liveIcons.count, id: \.self) { idx in
                                    liveIcons[idx](Color.dDefault)
                                        .frame(width: 24, height: 24)
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
                    .padding(.trailing, 16)
                    .padding(.leading, 16)
                }
                .buttonStyle(.plain)
                .background(Color.dBackground)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
                .padding(.top, safeAreaInsets.top)
                .padding(.leading, sideMargin)
            }
        }
    }

    private func toggleLiveActivity(for station: Station) {
        let isActive = isLiveActive(for: station)
        if isActive {
            Task {
                await liveActivityManager.stopLiveActivity(for: station.id)
            }
        } else {
            Task {
                await departuresViewModel.loadDepartures(for: station)
                await liveActivityManager.startLiveActivity(
                    station: station,
                    departures: departuresViewModel.filteredDepartures(for: station)
                )
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
            products: [.suburbanTrain, .bus, .regionalTrain, .highSpeedTrain],
        ),
        departuresViewModel: DeparturesViewModel(),
        onGearButtonTap: {}
    )
    .environmentObject(LiveActivityManager())
}
