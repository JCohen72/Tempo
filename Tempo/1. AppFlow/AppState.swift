//
//  AppState.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI
import Combine

/// Represents the high-level steps in the app's initial flow.
enum AppStep: Hashable {
    case login
    case questionnaireOne
    case questionnaireTwo
    case main
}

/// Global application state controlling navigation flow and user session.
/// In a production environment, AppState could handle token refresh, user profile loading, and more.
@MainActor
final class AppState: ObservableObject {
    @Published var step: AppStep = .login
    @Published var isLoggedIn: Bool = false
    
    /// Computed property linking `step` to a navigation path.
    /// Ensures a single source of truth for the current view state.
    var stepPath: [AppStep] {
        get { [step] }
        set {
            // Always keep only the last element as the current step
            if let last = newValue.last {
                step = last
            }
        }
    }
}
