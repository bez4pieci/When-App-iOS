import Foundation

struct CloudFunctionsEmulatorConfig {
    var enabled: Bool
    var host: String = "localhost"
    var port: Int = 5001

    init(enabled: Bool) {
        self.enabled = enabled
    }
}

enum AppConfig {
    static let cornerRadius: CGFloat = 24.0
    static let headerHeight: CGFloat = 240.0

    static let noStationId = "NO_STATION"

    static let cloudFunctionsRegion = "europe-west1"

    /// Cloud function emulation settings for debug mode
    static var cloudFunctionsEmulator: CloudFunctionsEmulatorConfig {
        #if DEBUG
            if ProcessInfo.processInfo.environment["CLOUD_FUNCTIONS_EMULATOR"] == "YES" {
                return CloudFunctionsEmulatorConfig(enabled: true)
            }
        #endif
        return CloudFunctionsEmulatorConfig(enabled: false)
    }
}
