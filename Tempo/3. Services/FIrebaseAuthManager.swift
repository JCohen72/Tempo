//
//  FIrebaseAuthManager.swift
//  Tempo
//
//  Created by Joey Cohen on 12/23/24.
//

import FirebaseAuth
import FirebaseFunctions
import SwiftUI

/// Manages Firebase sign-in with a custom token obtained from your
/// Cloud Function. Production-ready with robust error handling.
final class FirebaseAuthManager: ObservableObject {
    
    /// Shared instance if you want a singleton; or create an instance as needed.
    static let shared = FirebaseAuthManager()
    
    private lazy var functions = Functions.functions(region: "us-central1")
    
    private init() {}
    
    /**
     Signs the user into Firebase using a custom token from your Cloud Function.
     
     - Parameter spotifyAccessToken: The Spotify access token to validate
       with `/v1/me` on your server, which then issues a custom Firebase token.
     - Parameter alertManager: The shared `AlertManager` to display errors.
     - Returns: `true` if sign-in succeeded, `false` otherwise.
     */
    @MainActor
    func signInWithSpotify(spotifyAccessToken: String,
                           alertManager: AlertManager) async -> Bool {
        do {
            // 1) Call your Cloud Function to get a custom token
            let result = try await functions
                .httpsCallable("generateFirebaseToken")
                .call(["spotifyAccessToken": spotifyAccessToken])
            
            guard
                let data = result.data as? [String: Any],
                let customToken = data["token"] as? String
            else {
                alertManager.showAlert(title: "Error",
                                       message: "Invalid structure from Firebase function.")
                return false
            }
            
            // 2) Sign in with the custom token
            let authResult = try await Auth.auth().signIn(withCustomToken: customToken)
            
            // 3) Confirm the user object here
            guard authResult.user.uid.isEmpty == false else {
                alertManager.showAlert(title: "Error",
                                       message: "Firebase user ID missing after sign-in.")
                return false
            }
            
            return true
        } catch {
            alertManager.showAlert(title: "Firebase Sign-In Error",
                                   message: error.localizedDescription)
            return false
        }
    }
}
