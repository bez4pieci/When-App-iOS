import MapboxMaps
import SwiftUI

struct HeaderMap: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let station: Station?
    let offset: Double

    private var defaultLatitude = 48.8583
    private var defaultLongitude = 2.2923
    private var mapStyle: MapStyle = MapStyle(
        uri: StyleURI(rawValue: "mapbox://styles/bez4pieci/cmbwsv0y5019f01smb3fo9rvr")!)

    private var latitude: Double {
        station?.latitude ?? defaultLatitude
    }

    private var longitude: Double {
        station?.longitude ?? defaultLongitude
    }

    private var markerLabel: String {
        station?.name ?? "S+U Alexanderplatz"
    }

    private var viewport: Viewport {
        .camera(
            center: adjustedCenter(latitude: latitude, longitude: longitude),
            zoom: 15,
            bearing: 0,
            pitch: 30
        )
        .padding(
            EdgeInsets(
                top: safeAreaInsets.top,
                leading: 0,
                bottom: UIScreen.main.bounds.height - 240,
                trailing: 0
            )
        )
    }

    init(station: Station?, offset: Double) {
        self.station = station
        self.offset = offset
    }

    var body: some View {
        Map(viewport: .constant(viewport))
            .mapStyle(mapStyle)
            .ornamentOptions(
                OrnamentOptions(
                    scaleBar: ScaleBarViewOptions(visibility: .hidden)
                )
            )
            .allowsHitTesting(false)
    }

    private func adjustedCenter(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        var latitudeOffset: CLLocationDegrees = 0

        if offset < 0 {
            latitudeOffset += offset / 120000
        } else if offset < 120 {
            latitudeOffset += offset / 120000
        } else if offset >= 120 {
            latitudeOffset += 120 / 120000
        }

        // Adjust the center coordinate (subtract to move the visible center up)
        return CLLocationCoordinate2D(
            latitude: latitude - latitudeOffset,
            longitude: longitude
        )
    }
}

#Preview {
    HeaderMap(station: nil, offset: 0)
        .ignoresSafeArea(.all)
}

#Preview {
    HeaderMap(
        station: Station(
            id: "900058101",
            name: "S Südkreuz Bhf (Berlin)",
            latitude: 52.475501,
            longitude: 13.365548,
            products: [.suburbanTrain, .bus, .regionalTrain, .highSpeedTrain],
        ),
        offset: 0
    )
    .ignoresSafeArea(.all)
}
