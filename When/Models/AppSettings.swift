import Foundation
import SwiftUI

struct CloudFunctionsEmulator {
    var enabled: Bool = false
    var host: String = "localhost"
    var port: Int = 5001
}

struct AppSettings {
    /// Identify the user's device with a random UUID
    @AppStorage("userDeviceId") var userDeviceId: String = ""

    /// Cloud function emulation settings for debug mode
    var cloudFunctionsEmulator: CloudFunctionsEmulator = CloudFunctionsEmulator()

    init() {
        if userDeviceId.isEmpty {
            userDeviceId = UUID().uuidString
        }

        // Environment settings only for debug mode
        #if DEBUG
            if ProcessInfo.processInfo.environment["CLOUD_FUNCTIONS_EMULATOR"] == "YES" {
                cloudFunctionsEmulator.enabled = true
            }
        #endif
    }
}
