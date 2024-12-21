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
    @StateObject private var alertManager = AlertManager()
    @StateObject private var authManager: SpotifyAuthManager = {
        let aMgr = AlertManager()
        return SpotifyAuthManager(alertManager: aMgr)
    }()
    
    var body: some Scene {
        WindowGroup {
            AppFlowCoordinator()
                .environmentObject(appState)
                .environmentObject(alertManager)
                .environmentObject(authManager)
        }
    }
}
