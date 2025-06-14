import MapKit
import SwiftUI

struct HeaderMap: View {
    let station: Station?
    let offset: Double

    private var defaultLatitude = 48.8583
    private var defaultLongitude = 2.2923

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

    var body: some View {
        Map(
            position: .constant(
                .region(
                    MKCoordinateRegion(
                        center: adjustedCenter(
                            latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(
                            latitudeDelta: 0.03, longitudeDelta: 0.03)
                    )))
        ) {
            Marker(
                markerLabel,
                coordinate: CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                ))
        }
        .allowsHitTesting(false)

        // TODO: Find our why this is not working on iPhone 12
        //.overlay(Color.black.opacity(1).blendMode(.hue))
    }

    private func adjustedCenter(latitude: Double, longitude: Double) -> CLLocationCoordinate2D {
        // Get screen height
        let screenHeight = UIScreen.main.bounds.height
        let visibleHeight: CGFloat = 240

        // Calculate the offset needed to center the point in the visible area
        // The visible area is at the top, so we need to shift the center up
        let offsetRatio = (screenHeight - visibleHeight) / (2 * screenHeight)

        // Convert the offset ratio to latitude degrees
        // Using the current span as reference for the conversion
        let latitudeDelta = 0.03  // Same as the span's latitudeDelta
        var latitudeOffset = latitudeDelta * offsetRatio

        if offset < 0 {
            latitudeOffset += offset / 60000
        } else if offset < 120 {
            latitudeOffset += offset / 30000
        } else if offset >= 120 {
            latitudeOffset += 120 / 30000
        }

        // Adjust the center coordinate (subtract to move the visible center up)
        return CLLocationCoordinate2D(
            latitude: latitude - latitudeOffset,
            longitude: longitude
        )
    }
}
