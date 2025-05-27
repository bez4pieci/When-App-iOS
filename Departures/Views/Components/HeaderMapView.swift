import MapKit
import PhosphorSwift
import SwiftUI

struct HeaderMapView: View {
    let station: Station?
    let onGearButtonTap: () -> Void

    var body: some View {
        if let station = station,
            let latitude = station.latitude,
            let longitude = station.longitude
        {
            ZStack(alignment: .topTrailing) {
                Map(
                    position: .constant(
                        .region(
                            MKCoordinateRegion(
                                center: CLLocationCoordinate2D(
                                    latitude: latitude, longitude: longitude),
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )))
                ) {
                    Marker(
                        station.name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        ))
                }
                .frame(height: 200)
                .allowsHitTesting(false)

                gearButton
            }
            DefaultDivider()
        } else {
            HStack {
                Spacer()
                gearButton
            }
        }
    }

    private var gearButton: some View {
        Button(action: onGearButtonTap) {
            Ph.faders.regular.color(Color.dDefault)
                .frame(width: 24, height: 24)
                .padding(12)
        }
        .buttonStyle(.plain)
        .background(Color.yellow)
        .clipShape(Circle())
        .padding(.top, 60)
        .padding(.trailing, 16)
    }
}

#Preview {
    HeaderMapView(
        station: Station(
            id: "900100003",
            name: "S+U Alexanderplatz Bhf (Berlin)",
            latitude: 52.521508,
            longitude: 13.411267
        ),
        onGearButtonTap: {}
    )
}
