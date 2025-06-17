import CoreLocation
import MapboxMaps
import PhosphorSwift
import SwiftUI

struct HeaderMap: UIViewRepresentable {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let station: Station?
    let offset: Double

    // Default coordinates for Berlin Alexanderplatz
    private var defaultLatitude = 52.521508
    private var defaultLongitude = 13.411267

    private var styleURI = StyleURI(
        rawValue: "mapbox://styles/bez4pieci/cmbwsv0y5019f01smb3fo9rvr?cachebust=1612137633444")!

    private var latitude: Double {
        station?.latitude ?? defaultLatitude
    }

    private var longitude: Double {
        station?.longitude ?? defaultLongitude
    }

    private var markerLabel: String {
        station?.name ?? "S+U Alexanderplatz"
    }

    init(station: Station?, offset: Double) {
        self.station = station
        self.offset = offset
    }

    func makeUIView(context: Context) -> MapView {
        let coordinator = context.coordinator

        // Create the MapView with proper initialization
        let cameraOptions = CameraOptions(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            zoom: 15.5,
            bearing: 0,
            pitch: 30
        )
        let mapInitOptions = MapInitOptions(
            cameraOptions: cameraOptions,
            styleURI: styleURI
        )

        coordinator.mapView = MapView(frame: .zero, mapInitOptions: mapInitOptions)

        // Configure gesture options to disable all interactions
        coordinator.mapView.gestures.options = GestureOptions(
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

        // Configure ornament options
        coordinator.mapView.ornaments.options = OrnamentOptions(
            scaleBar: .init(visibility: .hidden),
            logo: .init(margins: CGPoint(x: 20, y: 8))
        )

        return coordinator.mapView
    }

    func updateUIView(_ uiView: MapView, context: Context) {
        let coordinator = context.coordinator

        // Check if station has changed
        let hasStationChanged = station?.id != coordinator.currentStationId

        // Update camera position
        let adjustedCenter = adjustedCenter(latitude: latitude, longitude: longitude)
        let cameraOptions = CameraOptions(
            center: adjustedCenter,
            padding: UIEdgeInsets(
                top: safeAreaInsets.top,
                left: 0,
                bottom: UIScreen.main.bounds.height - 240,
                right: 0
            ),
            zoom: 15.5,
            bearing: 0,
            pitch: 30
        )

        if hasStationChanged {
            // Use fly animation for station changes
            coordinator.mapView.camera.fly(to: cameraOptions, duration: 1.5)
            coordinator.updateAnnotation(
                for: station, latitude: latitude, longitude: longitude)
        } else {
            // Just set camera position for offset changes
            coordinator.mapView.mapboxMap.setCamera(to: cameraOptions)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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

// MARK: - Coordinator
extension HeaderMap {
    class Coordinator: NSObject {
        var parent: HeaderMap
        var mapView: MapView!
        private var currentAnnotation: ViewAnnotation?
        private(set) var currentStationId: String?

        init(_ parent: HeaderMap) {
            self.parent = parent
        }

        func updateAnnotation(for station: Station?, latitude: Double, longitude: Double) {
            let newStationId = station?.id
            currentStationId = newStationId

            // Remove existing annotation
            if let annotation = currentAnnotation {
                annotation.remove()
                currentAnnotation = nil
            }

            // Add new annotation if station exists
            guard let station = station else { return }

            let annotationView = createSwiftUIAnnotationView(for: station)
            let viewAnnotation = ViewAnnotation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                view: annotationView
            )

            viewAnnotation.allowOverlap = true
            viewAnnotation.allowZElevate = true
            viewAnnotation.variableAnchors = [
                ViewAnnotationAnchorConfig(anchor: .top, offsetY: 24 + 2)
            ]
            viewAnnotation.ignoreCameraPadding = true

            mapView.viewAnnotations.add(viewAnnotation)
            currentAnnotation = viewAnnotation
        }

        private func createSwiftUIAnnotationView(for station: Station) -> UIView {
            // Create SwiftUI view content
            let swiftUIView = VStack(spacing: 4) {
                Ph.mapPinSimple.regular
                    .frame(width: 24, height: 24)
                Text(station.name)
                    .font(Font.dSmall)
                Spacer()
            }
            .foregroundColor(.dAccent)
            .shadow(
                color: Color.black.opacity(0.6),
                radius: 1,
                x: 2,
                y: 2
            )

            // Convert SwiftUI view to UIView using UIHostingController
            let hostingController = UIHostingController(rootView: swiftUIView)
            hostingController.view.backgroundColor = .clear
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.widthAnchor.constraint(equalToConstant: 400).isActive =
                true
            hostingController.view.heightAnchor.constraint(equalToConstant: 100).isActive = true

            return hostingController.view
        }
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
