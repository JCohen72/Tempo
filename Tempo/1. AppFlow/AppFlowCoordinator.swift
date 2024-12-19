//
//  AppFlowCoordinator.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI

/// The top-level coordinator view, handling navigation based on `appState.step`.
/// Uses a NavigationStack to push and pop views according to the user's progress.
struct AppFlowCoordinator: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack(path: $appState.stepPath) {
            RootStepView()
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
                .onAppear {
                    // Ensure navigation path starts at current step
                    if appState.stepPath.isEmpty {
                        appState.stepPath = [appState.step]
                    }
                }
        }
    }
}

/// A root view that won't show anything but is needed to bootstrap NavigationStack destinations.
struct RootStepView: View {
    var body: some View {
        Color.clear
            .onAppear {
                // Intentionally empty. Navigation is controlled by AppFlowCoordinator.
            }
    }
}
