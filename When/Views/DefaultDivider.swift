import SwiftUI

struct DefaultDivider: View {
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.black.opacity(0.25))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Above")
        DefaultDivider()
        Text("Below")
    }
    .padding()
}
