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
    private var topPadding = 60.0
    private var styleURI: StyleURI

    private var latitude: Double {
        station?.latitude ?? defaultLatitude
    }

    private var longitude: Double {
        station?.longitude ?? defaultLongitude
    }

    private var markerLabel: String {
        station?.name.name ?? "S+U Alexanderplatz"
    }

    init(station: Station?, offset: Double) {
        self.station = station
        self.offset = offset

        var mapBoxPlist: [String: Any]?
        if let url = Bundle.main.url(forResource: "MapBox", withExtension: "plist") {
            do {
                let data = try Data(contentsOf: url)
                mapBoxPlist =
                    try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                    as? [String: Any]
            } catch {
                fatalError("Error reading MapBox.plist: \(error)")
            }
        }
        let accessToken = mapBoxPlist?["MBXAccessToken"] as? String
        let styleURI = mapBoxPlist?["StyleURI"] as? String

        guard let accessToken = accessToken else {
            fatalError("MapBox.plist is missing MBXAccessToken value")
        }

        MapboxOptions.accessToken = accessToken
        self.styleURI = StyleURI(rawValue: styleURI ?? "")!
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
                top: safeAreaInsets.top + topPadding,
                left: 0,
                bottom: UIScreen.main.bounds.height - AppConfig.headerHeight,
                right: 0
            ),
            zoom: 15.5,
            bearing: 0,
            pitch: 30
        )

        if hasStationChanged {
            animateCameraFromIntermediatePoint(
                coordinator: coordinator,
                cameraOptions: cameraOptions,
                targetCenter: adjustedCenter,
                latitude: latitude,
                longitude: longitude
            )
        } else {
            coordinator.mapView.mapboxMap.setCamera(to: cameraOptions)
        }
    }

    // Extracted method for animation logic
    private func animateCameraFromIntermediatePoint(
        coordinator: Coordinator,
        cameraOptions: CameraOptions,
        targetCenter: CLLocationCoordinate2D,
        latitude: Double,
        longitude: Double
    ) {
        let currentCenter = coordinator.mapView.mapboxMap.cameraState.center
        // Interpolate: intermediate = target * 0.9 + current * 0.1
        let intermediateLat = targetCenter.latitude * 0.9 + currentCenter.latitude * 0.1
        let intermediateLon = targetCenter.longitude * 0.9 + currentCenter.longitude * 0.1
        let intermediateCenter = CLLocationCoordinate2D(
            latitude: intermediateLat, longitude: intermediateLon)

        // Set camera immediately to the intermediate point (no animation)
        var intermediateCameraOptions = cameraOptions
        intermediateCameraOptions.center = intermediateCenter
        coordinator.mapView.mapboxMap.setCamera(to: intermediateCameraOptions)

        // Animate from intermediate to target
        let animator = coordinator.mapView.camera.makeAnimator(
            duration: 1,
            controlPoint1: CGPoint(x: 0.23, y: 1),
            controlPoint2: CGPoint(x: 0.32, y: 1),
        ) { transition in
            if let center = cameraOptions.center {
                transition.center.toValue = center
            }
            if let zoom = cameraOptions.zoom {
                transition.zoom.toValue = zoom
            }
            if let bearing = cameraOptions.bearing {
                transition.bearing.toValue = bearing
            }
            if let pitch = cameraOptions.pitch {
                transition.pitch.toValue = pitch
            }
            if let padding = cameraOptions.padding {
                transition.padding.toValue = padding
            }
        }
        animator.startAnimation()

        coordinator.updateAnnotation(
            for: station, latitude: latitude, longitude: longitude)
    }

    private func adjustedCenter(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        var latitudeOffset: CLLocationDegrees = 0

        let positiveScrollDamper = 1 / 140000.0
        let negativeScrollDamper = 1 / 120000.0

        let positiveThreshold = (AppConfig.headerHeight - topPadding) / 2

        if offset < 0 {
            latitudeOffset += offset * negativeScrollDamper
        } else if offset < positiveThreshold {
            latitudeOffset += offset * positiveScrollDamper
        } else if offset >= positiveThreshold {
            latitudeOffset += positiveThreshold * positiveScrollDamper
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
                Text(station.name.forDisplay)
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
            name: StationName(name: "S Südkreuz", extraPlace: "Berlin"),
            latitude: 52.475501,
            longitude: 13.365548,
            products: [.suburban, .bus, .regional, .express],
        ),
        offset: 0
    )
    .ignoresSafeArea(.all)
}

#Preview {
    HeaderMap(station: nil, offset: 0)
        .ignoresSafeArea(.all)
}
