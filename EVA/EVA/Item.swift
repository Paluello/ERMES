//
//  Item.swift
//  EVA
//
//  Created by Mattia Paluello on 03/11/25.
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
