import SwiftUI

extension Binding where Value == [String: Double] {
    subscript(key: String) -> Binding<Double> {
        Binding<Double>(
            get: { wrappedValue[key] ?? 0.0 },
            set: { wrappedValue[key] = $0 }
        )
    }
}
