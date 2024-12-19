//
//  AppFlowCoordinator.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI

struct AppFlowCoordinator: View {
    @EnvironmentObject var appState: AppState
    @State private var direction: NavigationDirection = .forward
    
    var body: some View {
        ZStack {
            switch appState.step {
            case .login:
                LoginView()
                    .transition(transitionForDirection(direction))
            case .questionnaireOne:
                QuestionnaireOneView()
                    .transition(transitionForDirection(direction))
            case .questionnaireTwo:
                QuestionnaireTwoView()
                    .transition(transitionForDirection(direction))
            case .main:
                MainView()
                    .transition(.opacity)
            }
        }
        .onChange(of: appState.step) { oldStep, newStep in
            withAnimation {
                direction = orderOf(newStep) > orderOf(oldStep) ? .forward : .backward
            }
        }
    }
    
    private func orderOf(_ step: AppStep) -> Int {
        switch step {
        case .login: return 0
        case .questionnaireOne: return 1
        case .questionnaireTwo: return 2
        case .main: return 3
        }
    }
    
    private func transitionForDirection(_ direction: NavigationDirection) -> AnyTransition {
        switch direction {
        case .forward:
            // Forward: Old out to left, New in from right
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            // Backward: Old out to right, New in from left
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }
}
