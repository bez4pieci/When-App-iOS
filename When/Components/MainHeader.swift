import MapKit
import PhosphorSwift
import SwiftUI

struct MainHeader: View {
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    let onGearButtonTap: () -> Void

    var body: some View {
        HStack {
            Spacer()
            gearButton
        }
    }

    private var gearButton: some View {
        Button(action: onGearButtonTap) {
            Ph.faders.regular.color(Color.dDefault)
                .frame(width: 24, height: 24)
                .padding(12)

                // Needed so that .plain button style takes the whole area as tappable, including the empty space
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.dBackground)
        .clipShape(Circle())
        .padding(.top, safeAreaInsets.top)
        .padding(.trailing, 16)
    }
}

#Preview {
    MainHeader(
        onGearButtonTap: {}
    )
}
