import MapboxMaps
import PhosphorSwift
import SwiftUI

struct HeaderMap: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let station: Station?
    let offset: Double

    @State private var currentViewport: Viewport

    // Default coordinates for Berlin Alexanderplatz
    private var defaultLatitude = 52.521508
    private var defaultLongitude = 13.411267

    private var mapStyle: MapStyle = MapStyle(
        uri: StyleURI(
            rawValue: "mapbox://styles/bez4pieci/cmbwsv0y5019f01smb3fo9rvr?cachebust=1612137633444")!
    )

    private var latitude: Double {
        station?.latitude ?? defaultLatitude
    }

    private var longitude: Double {
        station?.longitude ?? defaultLongitude
    }

    private var markerLabel: String {
        station?.name ?? "S+U Alexanderplatz"
    }

    private func createViewport(latitude: Double, longitude: Double) -> Viewport {
        .camera(
            center: adjustedCenter(latitude: latitude, longitude: longitude),
            zoom: 15.5,
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

        //Initialize the viewport with the current station or default coordinates
        let initialLatitude = station?.latitude ?? 48.8583
        let initialLongitude = station?.longitude ?? 2.2923
        self._currentViewport = State(
            initialValue: Viewport.camera(
                center: CLLocationCoordinate2D(
                    latitude: initialLatitude,
                    longitude: initialLongitude
                ),
                zoom: 15.5,
                bearing: 0,
                pitch: 30
            ))
    }

    var body: some View {
        Map(viewport: $currentViewport) {
            if let marker = marker {
                marker
            }
        }
        .mapStyle(mapStyle)
        .gestureOptions(
            GestureOptions.init(
                panEnabled: false,
                pinchEnabled: false,
                rotateEnabled: false,
                simultaneousRotateAndPinchZoomEnabled: false,
                pinchZoomEnabled: false,
                pinchPanEnabled: false,
                pitchEnabled: false,
                doubleTapToZoomInEnabled: false,
                doubleTouchToZoomOutEnabled: false,
                quickZoomEnabled: false
            )
        )
        .ornamentOptions(
            OrnamentOptions(
                scaleBar: .init(visibility: .hidden),
                logo: .init(margins: CGPoint(x: 20, y: 8))
            )
        )
        .onChange(of: station?.id) { _, _ in
            print("HeaderMap: Flying to to \(latitude), \(longitude)")
            withViewportAnimation(.fly(duration: 1.5)) {
                currentViewport = createViewport(latitude: latitude, longitude: longitude)
            }
        }
        .onChange(of: offset) { _, _ in
            currentViewport = createViewport(latitude: latitude, longitude: longitude)
        }
        .onAppear {
            currentViewport = createViewport(latitude: latitude, longitude: longitude)
        }
    }

    private var marker: MapViewAnnotation? {
        guard let station = station else {
            return nil
        }

        return MapViewAnnotation(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        ) {
            VStack(spacing: 4) {
                Ph.mapPinSimple.regular
                    .frame(width: 24, height: 24)
                Text(station.name)
                    .font(Font.dSmall)
            }
            .foregroundColor(.dAccent)
            .shadow(
                color: Color.black.opacity(0.6),
                radius: 1,
                x: 2,
                y: 2
            )
        }
        .priority(10)
        .allowOverlap(true)
        .allowZElevate(true)
        .variableAnchors([ViewAnnotationAnchorConfig(anchor: .bottom, offsetY: -32)])
        .ignoreCameraPadding(true)
    }

    private func adjustedCenter(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        var latitudeOffset: CLLocationDegrees = 0

        let positiveScrollDamper = 1 / 140000.0
        let negativeScrollDamper = 1 / 120000.0

        if offset < 0 {
            latitudeOffset += offset * negativeScrollDamper
        } else if offset < 120 {
            latitudeOffset += offset * positiveScrollDamper
        } else if offset >= 120 {
            latitudeOffset += 120 * positiveScrollDamper
        }

        // Adjust the center coordinate (subtract to move the visible center up)
        return CLLocationCoordinate2D(
            latitude: latitude - latitudeOffset,
            longitude: longitude
        )
    }
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

#Preview {
    HeaderMap(station: nil, offset: 0)
        .ignoresSafeArea(.all)
}
