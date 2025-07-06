import Foundation
import SwiftUI

struct AppSettings {
    /// Identify the user's device with a random UUID
    @AppStorage("userDeviceId") var userDeviceId: String = ""

    init() {
        if userDeviceId.isEmpty {
            userDeviceId = UUID().uuidString
        }
    }
}
