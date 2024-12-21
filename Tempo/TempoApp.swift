//
//  TempoApp.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

@main
struct TempoApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            AppFlowCoordinator()
                .environmentObject(appState)
        }
    }
}
