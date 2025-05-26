import MapKit
import SwiftUI

struct HeaderMapView: View {
    let station: Station?
    let onGearButtonTap: () -> Void

    private var region: MKCoordinateRegion {
        if let station = station,
            let latitude = station.latitude,
            let longitude = station.longitude
        {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
        // Default to Berlin center if no station
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }

    var body: some View {
        if let station = station,
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
            Image(systemName: "gearshape.fill")
                .font(.system(size: 24))
                .foregroundColor(station != nil ? Color.dDefault : .black)
                .padding(8)
                .background(station != nil ? Color.yellow : Color.yellow.opacity(0.8))
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 60)
        .padding(.trailing, 16)
    }
}

#Preview {
    HeaderMapView(
        station: Station(
            id: "1",
            name: "Alexanderplatz",
            latitude: 52.5219,
            longitude: 13.4132
        ),
        onGearButtonTap: {}
    )
}
