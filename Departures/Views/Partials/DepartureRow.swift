import SwiftUI
import SwiftData
import TripKit

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255
        )
    }
}

struct DepartureRow: View {
    let departure: Departure
    
    var body: some View {
        HStack {
            // Time
            Text(timeString)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(departureColor)
            
            // Line
            HStack(spacing: 4) {
                Text(departure.line.label ?? "")
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .font(Font.custom("DepartureMono-Regular", size: 14))
                    .background(Color(hex: departure.line.style?.backgroundColor ?? 0x808080))
                    .foregroundColor(Color(hex: departure.line.style?.foregroundColor ?? 0x000000))
                    .cornerRadius(departure.line.style?.shape == .rounded ? 4 : departure.line.style?.shape == .circle ? 100 : 0)
            }
            .frame(width: 80, alignment: .leading)
            
            // Destination
            Text(departure.destination?.name ?? "Unknown")
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Platform
            Text(departure.platform ?? "-")
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var timeString: String {
        if let predictedTime = departure.predictedTime {
            return formatTime(predictedTime)
        }
        return formatTime(departure.plannedTime)
    }
    
    private var departureColor: Color {
        if departure.cancelled {
            return .red.opacity(0.5)
        } else if let predictedTime = departure.predictedTime,
                  predictedTime > departure.plannedTime {
            return .red
        }
        return .green
    }
    
    private func lineBackgroundColor(for product: Product?) -> Color {
        guard let product = product else { return .gray }
        
        switch product {
        case .suburbanTrain:
            return Color(red: 0.0, green: 0.5, blue: 0.0) // S-Bahn green
        case .subway:
            return Color.blue // U-Bahn blue
        case .tram:
            return Color.red // Tram red
        case .bus:
            return Color.purple // Bus purple
        case .regionalTrain:
            return Color.orange // Regional trains
        default:
            return Color.gray
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}