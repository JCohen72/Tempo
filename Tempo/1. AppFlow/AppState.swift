//
//  AppState.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI
import Combine
import FirebaseAuth

/**
 This AppState manages local state (currentStep, completedOnboarding, navigationPath),
 plus merges or syncs with Firestore via `FirebaseData`.
 */
@MainActor
final class AppState: ObservableObject {
    @Published var navigationPath: [AppStep] = []
    
    @Published private(set) var currentStep: AppStep = .login
    @Published private(set) var completedOnboarding: Bool = false
    
    /// Our dedicated Firestore data layer
    private let firebaseData = FirebaseData()
    
    // MARK: - Init
    
    init() {
        loadFromDefaults()
    }
    
    // MARK: - Navigation Methods
    
    func push(_ step: AppStep) {
        navigationPath.append(step)
        currentStep = step
        persistState()
    }
    
    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
        
        currentStep = navigationPath.last ?? .login
        persistState()
    }
    
    func popToRoot() {
        navigationPath.removeAll()
        currentStep = .login
        persistState()
    }
    
    func finishOnboarding() {
        completedOnboarding = true
        push(.main)
    }
    
    // MARK: - Local Persistence
    
    private func loadFromDefaults() {
        let ud = UserDefaults.standard
        
        if
            let stepStr = ud.string(forKey: "CurrentAppStep"),
            let step = AppStep(rawValue: stepStr)
        {
            currentStep = step
        } else {
            currentStep = .login
        }
        
        completedOnboarding = ud.bool(forKey: "CompletedOnboarding")
    }
    
    private func saveToDefaults() {
        let ud = UserDefaults.standard
        ud.set(currentStep.rawValue, forKey: "CurrentAppStep")
        ud.set(completedOnboarding, forKey: "CompletedOnboarding")
    }
    
    // MARK: - Firestore Sync
    
    /**
     Persists the current state locally, then asynchronously saves it to Firestore.
     */
    private func persistState() {
        // 1) Local
        saveToDefaults()
        
        // 2) Remote
        Task {
            await saveToFirestore()
        }
    }
    
    /**
     Build a dictionary from our local state and call into `FirebaseData`
     to save it to Firestore, if the user is logged in.
     */
    private func saveToFirestore() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "currentStep": currentStep.rawValue,
            "completedOnboarding": completedOnboarding
        ]
        
        do {
            try await firebaseData.saveUserState(uid: uid, data: data)
        } catch {
            // For production, show via AlertManager or handle gracefully
            print("Error saving to Firestore: \(error.localizedDescription)")
        }
    }
    
    /**
     Fetches remote data from Firestore, merges or overrides local as needed.
     */
    func syncFromFirebase(alertManager: AlertManager, overrideLocal: Bool = true) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            if let remote = try await firebaseData.fetchUserState(uid: uid) {
                
                // Convert remote step from String -> AppStep
                let remoteStep = AppStep(rawValue: remote.currentStep) ?? .login
                
                if overrideLocal {
                    navigationPath.removeAll()
                    currentStep = remoteStep
                    completedOnboarding = remote.completedOnboarding
                    
                    // Save updated state locally so it’s remembered
                    saveToDefaults()
                } else {
                    // Custom merge logic if you prefer
                }
            }
        } catch {
            alertManager.showAlert(
                title: "Fetch Error",
                message: "Could not load remote state: \(error.localizedDescription)"
            )
        }
    }
}
