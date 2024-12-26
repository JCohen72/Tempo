//
//  RootView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/26/24.
//

import SwiftUI

/**
 A blank (or minimal spinner) view shown on app launch.
 It decides if the user should see the LoginView or skip ahead
 (Q1, Q2, main) based on local + token refresh checks.
 */
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var alertManager: AlertManager

    var body: some View {
        ZStack {
            Color.clear.edgesIgnoringSafeArea(.all)
            ProgressView("Loading...")
                .progressViewStyle(.circular)
        }
        .task {
            await route(shouldRefresh: true)
        }
    }
}

// MARK: - Private Helpers
extension RootView {
    /**
     Attempts to refresh tokens; if user is valid => maybe sync Firestore,
     then decide if we push .login or the last step.
     */
    private func route(shouldRefresh: Bool) async {
        if shouldRefresh {
            let validToken = await authManager.refreshIfNeeded()
            if validToken && authManager.isLoggedIn {
                // Optional: try to fetch remote data
                await appState.syncFromFirebase(alertManager: alertManager)
            }
        }
        
        // If never logged in or is logged out => show login
        if !authManager.isLoggedIn {
            appState.push(.login)
        } else {
            // Otherwise resume from local state
            if appState.completedOnboarding {
                appState.push(.main)
            } else {
                appState.push(appState.currentStep) // Q1 or Q2
            }
        }
    }
}
