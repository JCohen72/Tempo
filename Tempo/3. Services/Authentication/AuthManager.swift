//
//  AuthManager.swift
//  Tempo
//
//  Created by Joey Cohen on 12/25/24.
//

import SwiftUI
import Combine

/**
 A single manager that coordinates authentication steps using:
 - SpotifyAuthManager for the PKCE flow + storing tokens
 - FirebaseAuthManager for converting the Spotify token into a Firebase sign-in

 Ensures both services remain in sync:
 - If Spotify login fails, we revert any partial Firebase login
 - If Firebase login fails, we revert any partial Spotify login
 - A user is only truly "logged in" if both services succeed
 */
final class AuthManager: ObservableObject {
    /// True if *both* Spotify + Firebase are currently authenticated
    @Published private(set) var isLoggedIn: Bool = false
    
    /// Individual states for each provider
    @Published private(set) var isSpotifyLoggedIn: Bool = false
    @Published private(set) var isFirebaseLoggedIn: Bool = false
    
    private let spotifyAuthManager: SpotifyAuthManager
    private let firebaseAuthManager: FirebaseAuthManager
    private let alertManager: AlertManager
    
    init(
        spotifyAuthManager: SpotifyAuthManager,
        firebaseAuthManager: FirebaseAuthManager,
        alertManager: AlertManager
    ) {
        self.spotifyAuthManager  = spotifyAuthManager
        self.firebaseAuthManager = firebaseAuthManager
        self.alertManager        = alertManager
        
        // Attempt to see if there are any stored tokens
        // so we can update isSpotifyLoggedIn or isFirebaseLoggedIn
        updateServiceStates()
    }
    
    // MARK: - Provide convenience calls for the UI
    
    /**
     Builds the URL needed to start the Spotify login.
     */
    func makeAuthorizationURL() -> URL? {
        return spotifyAuthManager.makeAuthorizationURL()
    }
    
    public func currentUserUID() -> String? {
        return firebaseAuthManager.currentFirebaseUID()
    }
    
    /**
     Main login: Exchange the Spotify authorization code for tokens,
     then sign in to Firebase. If either fails, revert to a clean state.
     */
    @MainActor
    func exchangeCodeForTokens(code: String) async {
        do {
            // 1) Exchange code with Spotify (for Spotify tokens).
            try await spotifyAuthManager.exchangeCodeForTokensSpotify(code: code)
            
            // Update Spotify state
            self.isSpotifyLoggedIn = true
            
            // 2) Attempt Firebase sign-in using the new Spotify access token
            guard let spotifyAccessToken = spotifyAuthManager.loadAccessToken() else {
                alertManager.showAlert(
                    title: "Error",
                    message: "Failed retrieving Spotify access token after code exchange."
                )
                // Revert Spotify if we can’t proceed
                logoutSpotifyOnly()
                return
            }
            
            let firebaseSuccess = await firebaseAuthManager.signInWithSpotify(
                spotifyAccessToken: spotifyAccessToken,
                alertManager: alertManager
            )
            
            if !firebaseSuccess {
                // Showed alert in signInWithSpotify. Now revert Spotify so we aren’t half-auth’d
                logoutSpotifyOnly()
                return
            }
            
            // If we got this far, both Spotify + Firebase are in sync
            self.isFirebaseLoggedIn = true
            self.isLoggedIn = true
            
        } catch {
            // If the Spotify exchange fails, show an alert and revert
            alertManager.showAlert(
                title: "Error",
                message: "Exchange code error: \(error.localizedDescription)"
            )
            logoutSpotifyOnly()
        }
    }
    
    /**
     Attempt to refresh Spotify tokens if needed, then confirm the overall login state.
     If Spotify is valid, we optionally verify Firebase is still signed in.
     */
    @discardableResult
    func refreshIfNeeded() async -> Bool {
        let refreshed = await spotifyAuthManager.refreshIfNeededSpotify()
        
        await MainActor.run {
            if refreshed {
                // If we still have a valid Spotify token, assume Spotify is "logged in"
                self.isSpotifyLoggedIn = true
                // For production, we might want to re-check FirebaseAuth.currentUser != nil
                // but if we trust the user is still signed in to Firebase:
                self.isFirebaseLoggedIn = (firebaseAuthManager.currentFirebaseUID() != nil)
                self.isLoggedIn = self.isSpotifyLoggedIn && self.isFirebaseLoggedIn
            } else {
                // Revert both if refresh fails
                logout()
            }
        }
        
        return refreshed
    }
    
    /**
     Logout from both Spotify + Firebase, then mark logged out.
     If either sign-out fails, we revert so both remain consistent.
     */
    func logout() {
        // Attempt Spotify sign-out
        let spotifyDidLogout = logoutSpotifyOnly()
        
        // Attempt Firebase sign-out
        let firebaseDidLogout = firebaseAuthManager.signOutOfFirebase(alertManager: alertManager)
        
        // If either fails, show an alert and revert
        if !spotifyDidLogout || !firebaseDidLogout {
            alertManager.showAlert(
                title: "Warning",
                message: """
                One or more services failed to log out completely. 
                We'll revert them to ensure your session ends.
                """
            )
        }
        
        // Final step: Mark everything as logged out
        self.isSpotifyLoggedIn = false
        self.isFirebaseLoggedIn = false
        self.isLoggedIn = false
    }
    
    // MARK: - Private Helpers
    
    /**
     Logs out Spotify only. Used to roll back partial logins if Firebase fails.
     Returns true if no errors happened, else false.
     */
    @discardableResult
    private func logoutSpotifyOnly() -> Bool {
        let success = spotifyAuthManager.logoutSpotify()
        if success {
            self.isSpotifyLoggedIn = false
        }
        return success
    }
    
    /**
     Checks any stored credentials in the keychain / Auth state
     to update the current boolean states upon init if needed.
     */
    private func updateServiceStates() {
        self.isSpotifyLoggedIn = (spotifyAuthManager.loadAccessToken() != nil)
        self.isFirebaseLoggedIn = (firebaseAuthManager.currentFirebaseUID() != nil)
        self.isLoggedIn = (isSpotifyLoggedIn && isFirebaseLoggedIn)
    }
    
    // MARK: - Optionally expose re-usable methods for other flows
    func loadAccessToken() -> String? {
        return spotifyAuthManager.loadAccessToken()
    }
}
