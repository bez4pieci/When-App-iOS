import SwiftUI

struct PrimaryButton: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .foregroundColor(.black)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(Color.yellow)
                .cornerRadius(8)
        }
    }
}

#Preview {
    PrimaryButton(text: "SELECT STATION") {
        print("Button tapped")
    }
} 