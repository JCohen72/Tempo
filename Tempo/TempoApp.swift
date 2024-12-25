//
//  TempoApp.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

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
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    
    @StateObject private var appState = AppState()
    @StateObject private var alertManager = AlertManager()
    @StateObject private var authManager: AuthManager = {
        let alertMgr   = AlertManager()
        let spotifyMgr = SpotifyAuthManager(alertManager: alertMgr)
        let firebaseMgr = FirebaseAuthManager.shared
        
        return AuthManager(
            spotifyAuthManager: spotifyMgr,
            firebaseAuthManager: firebaseMgr,
            alertManager: alertMgr
        )
    }()
    
    var body: some Scene {
        WindowGroup {
            AppFlowCoordinator()
                // Testing purposes only:
                // .onAppear { authManager.logout() }
                .environmentObject(appState)
                .environmentObject(alertManager)
                .environmentObject(authManager)
        }
    }
}
