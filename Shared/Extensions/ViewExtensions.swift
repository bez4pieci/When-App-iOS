import SwiftUI

// MARK: - Color Extension
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }

    static let dDefault = Color(hex: 0x000000)
    static let dMedium = Color(hex: 0x000000, alpha: 0.8)
    static let dLight = Color(hex: 0x000000, alpha: 0.6)
}

// MARK: - Font Extension
extension Font {
    static let dSmall = Font.custom("DepartureMono-Regular", size: 16)
    static let dNormal = Font.custom("DepartureMono-Regular", size: 20)
    static let dLarge = Font.custom("DepartureMono-Regular", size: 24)
}

// MARK: - TextFieldStyle
struct DefaultTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(Font.dNormal)
    }
}
