//
//  AppFlowCoordinator.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI

struct AppFlowCoordinator: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: SpotifyAuthManager
    @EnvironmentObject private var alertManager: AlertManager
    
    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            // Root view is the LoginView
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
            // Fix .task and .onchange for single source of truth --> BUG
                .task {
                    guard !authManager.isLoggedIn else { return }
                    
                    let hasValidToken = await authManager.refreshIfNeeded()
                    if hasValidToken {
                        appState.push(.main)
                    }
                }
                .onChange(of: authManager.isLoggedIn) {
                    if authManager.isLoggedIn {
                        appState.push(.questionnaireOne)
                    }
                }

        }
    }
}
