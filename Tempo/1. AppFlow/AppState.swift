//
//  AppState.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published var navigationPath: [AppStep] = []

    func push(_ step: AppStep) {
        navigationPath.append(step)
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeAll()
    }
}
