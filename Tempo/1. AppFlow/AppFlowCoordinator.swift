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
                // Whenever user logs in/out, we handle changes
                .onChange(of: authManager.isLoggedIn) {
                    Task { await route(shouldRefresh: false) }
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

// MARK: - Routing Helpers
extension AppFlowCoordinator {
    /**
     Called whenever `isLoggedIn` changes mid-session (e.g. user logs out).
     Decide if we pop to .login or remain in the current step.
     */
    private func route(shouldRefresh: Bool) async {
        // If refresh is requested:
        if shouldRefresh {
            let validToken = await authManager.refreshIfNeeded()
            if validToken && authManager.isLoggedIn {
                // optional Firestore sync
                await appState.syncFromFirebase(alertManager: alertManager)
            }
        }
        
        if authManager.isLoggedIn {
            // If user is newly logged in, maybe skip to .main or current step
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
