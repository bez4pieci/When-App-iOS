//
//  MainView 2.swift
//  Departures
//
//  Created by Ernests Karlsons on 24.05.25.
//

import MapKit
import SwiftData
import SwiftUI
import TripKit

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Station.selectedAt, order: .reverse) private var stations: [Station]

    @State private var departures: [Departure] = []
    @State private var isLoading = false
    @State private var showStationSelection = false
    @State private var lastUpdate = Date()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),  // Berlin center
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    private var selectedStation: Station? {
        stations.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.yellow.ignoresSafeArea()

                VStack(spacing: 0) {
                    if let station = selectedStation,
                        let latitude = station.latitude,
                        let longitude = station.longitude
                    {
                        ZStack(alignment: .topTrailing) {
                            Map(position: .constant(.region(region))) {
                                Marker(
                                    station.name,
                                    coordinate: CLLocationCoordinate2D(
                                        latitude: latitude,
                                        longitude: longitude
                                    ))
                            }
//                            .mapStyle(.imagery(elevation: .realistic))
                            .frame(height: 200)
                            .allowsHitTesting(false)

                            Button(action: { showStationSelection = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(Color.dDefault)
                                    .padding(8)
                                    .background(Color.yellow)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 60)
                            .padding(.trailing, 16)
                        }
                        DefaultDivider()

                    } else {
                        HStack {
                            Spacer()
                            Button(action: { showStationSelection = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.black)
                                    .padding(8)
                                    .background(Color.yellow.opacity(0.8))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 60)
                            .padding(.trailing, 16)
                        }
                    }

                    if selectedStation != nil {
                        DepartureBoardView(
                            departures: departures,
                            onRefresh: loadDepartures
                        )
                    } else {
                        NoStationView(onSelectStation: { showStationSelection = true })
                    }
                }
                .ignoresSafeArea()
                .navigationBarHidden(true)
            }
            .task {
                await loadDepartures()
            }
            .onAppear {
                if let station = selectedStation,
                    let latitude = station.latitude,
                    let longitude = station.longitude
                {
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            }
            .onChange(of: selectedStation) { _, newStation in
                if let station = newStation,
                    let latitude = station.latitude,
                    let longitude = station.longitude
                {
                    dump(station)
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                if newStation != nil {
                    Task {
                        await loadDepartures()
                    }
                }
            }
            .sheet(isPresented: $showStationSelection) {
                StationSelectionView()
            }
        }
    }

    private func loadDepartures() async {
        guard let station = selectedStation else { return }

        isLoading = true
        defer { isLoading = false }

        // Create a task to ensure minimum loading time
        async let minimumLoadingTime = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)  // 1 second
        }

        do {
            let provider = BvgProvider(apiAuthorization: [
                "type": "AID", "aid": "dVg4TZbW8anjx9ztPwe2uk4LVRi9wO",
            ])

            let (_, result) = await provider.queryDepartures(stationId: station.id)

            // Wait for both the API call and minimum loading time to complete
            _ = await (minimumLoadingTime, result)

            switch result {
            case .success(let stationDepartures):
                await MainActor.run {
                    self.departures = stationDepartures.flatMap { $0.departures }
                    self.lastUpdate = Date()
                }
            case .invalidStation:
                print("Invalid station id")
            case .failure(let error):
                print("Error loading departures: \(error)")
            }
        } catch {
            print("Error loading departures: \(error)")
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }
}
