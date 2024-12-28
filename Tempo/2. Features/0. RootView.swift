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
 
 Requirements Satisfied Here:
 0) Load blank view first so there's no flicker.
 1) If user never logged in or is logged out => .login
 2) If user was last in Q1/Q2/Main => restore to that step
 3) Local is priority. If local is missing but user is logged in, fetch from Firestore once.
    If remote also missing => .login
 */
struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var alertManager: AlertManager

    var body: some View {
        ZStack {
            Color.clear.edgesIgnoringSafeArea(.all)
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.5)
        }
        .task {
            await handleInitialLaunch()
        }
    }
}

extension RootView {
    private func handleInitialLaunch() async {
        // 1) Attempt token refresh
        let validToken = await authManager.refreshIfNeeded()

        // 2) Check if user is logged in
        guard validToken, authManager.isLoggedIn else {
            // No animation for the initial push to .login
            withTransaction(Transaction(animation: nil)) {
                appState.popToRoot()
                appState.push(.login)
            }
            return
        }
        
        // 3) If user is logged in => check if local data is missing
        if appState.isLocalDataMissing {
            do {
                let foundRemote = try await appState.syncFromFirebaseBlockingIfNeeded(
                    alertManager: alertManager
                )
                if foundRemote {
                    // No animation for the first push from root
                    withTransaction(Transaction(animation: nil)) {
                        routeFromAppState()
                    }
                } else {
                    withTransaction(Transaction(animation: nil)) {
                        appState.popToRoot()
                        appState.push(.login)
                    }
                }
            } catch {
                alertManager.showAlert(
                    title: "Fetch Error",
                    message: "Could not load remote state: \(error.localizedDescription)"
                )
                withTransaction(Transaction(animation: nil)) {
                    appState.popToRoot()
                    appState.push(.login)
                }
            }
        } else {
            // Local data is present => push immediately, no flicker
            withTransaction(Transaction(animation: nil)) {
                routeFromAppState()
            }
            // Then do a background Firestore sync if desired
            Task {
                await appState.syncFromFirebase(alertManager: alertManager, overrideLocal: false)
            }
        }
    }
    
    private func routeFromAppState() {
        if appState.completedOnboarding {
            appState.push(.main)
        } else {
            appState.push(appState.currentStep)
        }
    }
}
