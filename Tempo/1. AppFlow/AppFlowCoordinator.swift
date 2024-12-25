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
            LoginView()
                .navigationDestination(for: AppStep.self) { step in
                    switch step {
                    case .questionnaireOne:
                        QuestionnaireOneView()
                    case .questionnaireTwo:
                        QuestionnaireTwoView()
                    case .main:
                        MainView()
                    }
                }
                .task {
                    // If we have partial tokens, attempt to refresh
                    let hasValidToken = await authManager.refreshIfNeeded()
                    if hasValidToken {
                        // If after refresh, both Spotify + Firebase are valid:
                        if authManager.isLoggedIn {
                            appState.push(.questionnaireOne)
                        }
                    } else {
                        // If refresh not valid or fails, ensure root
                        appState.popToRoot()
                    }
                }
                // Observe changes in isLoggedIn to handle re-routes
                .onChange(of: authManager.isLoggedIn) {
                    if authManager.isLoggedIn {
                        // Both services are now logged in => push to Q1
                        appState.push(.questionnaireOne)
                    } else {
                        // They got logged out => ensure we’re at root
                        appState.popToRoot()
                    }
                }
        }
        .alert(item: $alertManager.alertMessage) { alertData in
            Alert(
                title: Text(alertData.title),
                message: Text(alertData.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
