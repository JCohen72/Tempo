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
 Manages in-memory app state (currentStep, completedOnboarding, navigationPath),
 orchestrates local + remote sync with dedicated store objects.
 */
@MainActor
final class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var navigationPath: [AppStep] = []
    @Published private(set) var currentStep: AppStep = .login
    @Published private(set) var completedOnboarding: Bool = false
    
    // MARK: - Stores
    private let localStore = LocalStateStore()
    private let remoteStore = RemoteStateStore()
    
    // MARK: - Init
    init() {
        loadFromLocalStore()
    }
    
    // MARK: - Derived
    var isLocalDataMissing: Bool {
        // If we're stuck at .login with no onboarding completed,
        // but the user is logged in, that suggests local data is incomplete.
        currentStep == .login && completedOnboarding == false
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
    private func loadFromLocalStore() {
        self.currentStep = localStore.loadAppStep()
        self.completedOnboarding = localStore.loadCompletedOnboarding()
    }
    
    private func saveToLocalStore() {
        localStore.saveAppStep(currentStep)
        localStore.saveCompletedOnboarding(completedOnboarding)
    }
    
    // MARK: - Firestore Sync
    private func persistState(alertManager: AlertManager? = nil) {
        // 1) Save locally
        saveToLocalStore()
        
        // 2) Save to remote in background
        Task {
            await saveToFirestore(alertManager: alertManager)
        }
    }
    
    /// Convenience: calls `persistState()` with no alert manager.
    private func persistState() {
        persistState(alertManager: nil)
    }
    
    private func saveToFirestore(alertManager: AlertManager?) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let data: [String: Any] = [
            "currentStep": currentStep.rawValue,
            "completedOnboarding": completedOnboarding
        ]
        
        do {
            try await remoteStore.saveUserState(uid: uid, data: data)
        } catch {
            alertManager?.showAlert(
                title: "Save Error",
                message: "Unable to save your data to Firestore: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     Fetches remote data from Firestore, merges or overrides local as needed.
     - Parameter alertManager: The global alert manager for showing user-facing errors.
     - Parameter overrideLocal: If true, local state is overwritten with remote.
     */
    func syncFromFirebase(
        alertManager: AlertManager,
        overrideLocal: Bool = true
    ) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        do {
            if let remote = try await remoteStore.fetchUserState(uid: uid) {
                let remoteStep = AppStep(rawValue: remote.currentStep) ?? .login
                if overrideLocal {
                    navigationPath.removeAll()
                    currentStep = remoteStep
                    completedOnboarding = remote.completedOnboarding
                    saveToLocalStore()
                } else {
                    // Potential place for a custom merge if partial data is local
                }
            }
        } catch {
            alertManager.showAlert(
                title: "Fetch Error",
                message: "Could not load remote state: \(error.localizedDescription)"
            )
        }
    }
    
    /**
     If local data is missing but the user is authenticated, do a **blocking** fetch from Firestore.
     - Throws: An error if the network call fails, so the caller can respond.
     - Returns: `true` if remote data was found and applied, or `false` if no doc existed.
     */
    func syncFromFirebaseBlockingIfNeeded(alertManager: AlertManager) async throws -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AppState", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "No valid user UID"
            ])
        }
        
        do {
            if let remote = try await remoteStore.fetchUserState(uid: uid) {
                navigationPath.removeAll()
                currentStep = AppStep(rawValue: remote.currentStep) ?? .login
                completedOnboarding = remote.completedOnboarding
                saveToLocalStore()
                return true
            } else {
                // Doc doesn't exist => treat as "no data"
                return false
            }
        } catch {
            // Expose this error to the caller so it can handle UI
            throw error
        }
    }
}
