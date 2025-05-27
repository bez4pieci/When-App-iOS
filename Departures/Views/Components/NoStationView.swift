
import SwiftUI

struct NoStationView: View {
    let onSelectStation: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            PrimaryButton(text: "Select a station", action: onSelectStation)
        }
        .frame(maxHeight: .infinity)
    }
} 