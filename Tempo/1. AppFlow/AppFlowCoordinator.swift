//
//  AppFlowCoordinator.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI

struct AppFlowCoordinator: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var alertManager: AlertManager
    
    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            // Initial content: LaunchView
            RootView()
                .navigationDestination(for: AppStep.self) { step in
                    switch step {
                    case .login:
                        LoginView()
                    case .questionnaireOne:
                        QuestionnaireOneView()
                    case .questionnaireTwo:
                        QuestionnaireTwoView()
                    case .main:
                        MainView()
                    }
                }
                // Handle mid-session login/logout changes
                .onChange(of: authManager.isLoggedIn) {
                    Task { await handleAuthChange(shouldRefresh: false) }
                }
        }
        // Show alerts from alertManager
        .alert(item: $alertManager.alertMessage) { alertData in
            Alert(
                title: Text(alertData.title),
                message: Text(alertData.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

// MARK: - Routing on Login/Logout Change
extension AppFlowCoordinator {
    /**
     Called whenever `isLoggedIn` changes mid-session, e.g. user logs out or logs in again.
     - Parameter shouldRefresh: If true, attempt to refresh tokens (optional).
     */
    private func handleAuthChange(shouldRefresh: Bool) async {
        if shouldRefresh {
            let validToken = await authManager.refreshIfNeeded()
            if validToken && authManager.isLoggedIn {
                await appState.syncFromFirebase(alertManager: alertManager, overrideLocal: false)
            }
        }
        
        if authManager.isLoggedIn {
            // If user is already logged in, resume from local step or main
            if appState.completedOnboarding {
                appState.push(.main)
            } else {
                appState.push(appState.currentStep)
            }
        } else {
            // If user logs out, pop to root + push .login
            appState.popToRoot()
            appState.push(.login)
        }
    }
}
