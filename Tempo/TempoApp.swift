//
//  TempoApp.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI
import FirebaseCore

@main
struct TempoApp: App {
    // Connects your custom AppDelegate to the SwiftUI App lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    @StateObject private var appState = AppState()
    @StateObject private var alertManager = AlertManager()
    
    // THIS DOESN'T SEEM RIGHT, CHECK---------------------------------------->
    @StateObject private var authManager: SpotifyAuthManager = {
        let aMgr = AlertManager()
        return SpotifyAuthManager(alertManager: aMgr)
    }()
    
    var body: some Scene {
        WindowGroup {
            AppFlowCoordinator()
            // Testing purposes only
//                .onAppear {
//                    authManager.logout()
//                }
                .environmentObject(appState)
                .environmentObject(alertManager)
                .environmentObject(authManager)
        }
    }
}
