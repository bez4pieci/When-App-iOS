import Foundation
import SwiftUI

// TODO: Refactor to @Observable
class AppSettings: ObservableObject {
    @AppStorage("userDeviceId") var userDeviceId: String = ""

    init() {
        if userDeviceId.isEmpty {
            userDeviceId = UUID().uuidString
        }
    }
}
