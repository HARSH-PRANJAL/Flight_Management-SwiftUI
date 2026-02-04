//
//  Item.swift
//  Flight_Management
//
//  Created by Harsh Pranjal on 04/02/26.
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
