//
//  FIrebaseAuthManager.swift
//  Tempo
//
//  Created by Joey Cohen on 12/23/24.
//

import FirebaseAuth
import FirebaseFunctions
import SwiftUI

final class FirebaseAuthManager: ObservableObject {
    
    static let shared = FirebaseAuthManager()
    private lazy var functions = Functions.functions(region: "us-central1")
    
    private init() {}
    
    /**
     Attempts Firebase sign-in with the provided Spotify access token.
     Returns `true` if successful, `false` otherwise.
     All alerts are shown via `alertManager`.
     */
    @MainActor
    func signInWithSpotify(
        spotifyAccessToken: String,
        alertManager: AlertManager
    ) async -> Bool {
        do {
            let result = try await functions
                .httpsCallable("generateFirebaseToken")
                .call(["spotifyAccessToken": spotifyAccessToken])
            
            guard
                let data = result.data as? [String: Any],
                let customToken = data["token"] as? String
            else {
                alertManager.showAlert(
                    title: "Error",
                    message: "Invalid structure from Firebase function."
                )
                return false
            }
            
            let authResult = try await Auth.auth().signIn(withCustomToken: customToken)
            guard authResult.user.uid.isEmpty == false else {
                alertManager.showAlert(
                    title: "Error",
                    message: "Firebase user ID missing after sign-in."
                )
                return false
            }
            
            return true
        } catch let error as NSError {
            if let functionsError = error.userInfo[FunctionsErrorDetailsKey] as? [String: Any],
               let code = functionsError["code"] as? String,
               let details = functionsError["details"] as? String {
                alertManager.showAlert(
                    title: "Firebase Sign-In Error (\(code))",
                    message: details
                )
            } else {
                alertManager.showAlert(
                    title: "Firebase Sign-In Error",
                    message: error.localizedDescription
                )
            }
            return false
        } catch {
            alertManager.showAlert(
                title: "Firebase Sign-In Error",
                message: error.localizedDescription
            )
            return false
        }
    }
    
    /**
     Returns the currently signed-in Firebase user’s UID, or nil if not signed in.
     */
    func currentFirebaseUID() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    /**
     Logs out of Firebase, returning `true` if no errors occurred.
     Otherwise false, with an alert displayed via `alertManager`.
     */
    @discardableResult
    func signOutOfFirebase(alertManager: AlertManager) -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            alertManager.showAlert(
                title: "Error",
                message: "Failed logging out of Firebase: \(error.localizedDescription)"
            )
            return false
        }
    }
}
