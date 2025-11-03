//
//  EVAApp.swift
//  EVA
//
//  Created by Mattia Paluello on 03/11/25.
//

import SwiftUI

@main
struct EVAApp: App {
    @StateObject private var streamManager = StreamManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                StreamControlView(streamManager: streamManager)
            }
        }
    }
}
