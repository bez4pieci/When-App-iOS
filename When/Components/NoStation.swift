import SwiftUI

struct NoStation: View {
    let onSelectStation: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Button(action: onSelectStation) {
                Text("Select a station")
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.yellow)
                    .cornerRadius(8)
            }
        }
        .frame(maxHeight: .infinity)
    }
}
