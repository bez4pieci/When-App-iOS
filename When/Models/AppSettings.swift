import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    @AppStorage("userDeviceId") var userDeviceId: String = ""

    init() {
        if userDeviceId.isEmpty {
            userDeviceId = UUID().uuidString
        }
    }
}
