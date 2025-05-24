//
//  Item.swift
//  Departures
//
//  Created by Ernests Karlsons on 24.05.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
