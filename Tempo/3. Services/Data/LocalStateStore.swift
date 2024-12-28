//
//  LocalStateStore.swift
//  Tempo
//
//  Created by Joey Cohen on 12/28/24.
//

import Foundation
import SwiftUI

/// Handles all local (UserDefaults) persistence for the app’s state.
final class LocalStateStore {
    private let ud = UserDefaults.standard
    
    func loadAppStep() -> AppStep {
        guard let stepStr = ud.string(forKey: "CurrentAppStep"),
              let step = AppStep(rawValue: stepStr) else {
            return .login
        }
        return step
    }
    
    func saveAppStep(_ step: AppStep) {
        ud.set(step.rawValue, forKey: "CurrentAppStep")
    }
    
    func loadCompletedOnboarding() -> Bool {
        ud.bool(forKey: "CompletedOnboarding")
    }
    
    func saveCompletedOnboarding(_ completed: Bool) {
        ud.set(completed, forKey: "CompletedOnboarding")
    }
}
