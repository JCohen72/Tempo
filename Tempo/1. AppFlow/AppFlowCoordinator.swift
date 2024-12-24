//
//  AppFlowCoordinator.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

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
                // Perform refresh in a dedicated .task on the coordinator itself,
                // rather than in SpotifyAuthManager's init
                .task {
                    // 3) Add guard to avoid doing repeated refresh attempts if needed
                    guard !authManager.isLoggedIn else { return }
                    
                    let hasValidToken = await authManager.refreshIfNeeded()
                    if hasValidToken {
                        appState.push(.questionnaireOne)
                    } else {
                        appState.popToRoot()
                    }
                }
                // Listen for login changes and navigate forward
                .onChange(of: authManager.isLoggedIn) {
                    if authManager.isLoggedIn {
                        // We move the navigation logic from LoginView to the coordinator
                        // This keeps LoginView "dumb" and focuses it purely on login action
                        appState.push(.questionnaireOne)
                    }
                }
        }
    }
}
