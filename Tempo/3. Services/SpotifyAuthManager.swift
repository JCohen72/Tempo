//
//  SpotifyAuthManager.swift
//  Tempo
//
//  Created by Joey Cohen on 12/21/24.
//

import SwiftUI
import CryptoKit
import FirebaseAuth

final class SpotifyAuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    private let keyAccessToken    = "SpotifyAccessToken"
    private let keyRefreshToken   = "SpotifyRefreshToken"
    private let keyExpirationDate = "SpotifyExpirationDate"
    private let keyCodeVerifier   = "SpotifyPKCE_verifier"  // PKCE stored in Keychain if needed
    
    let alertManager: AlertManager
    
    /// PKCE code verifier stored in-memory. Retrieve from Keychain if app restarts mid-auth.
    private var codeVerifierInMemory: String = ""
    
    // MARK: - Init
    init(alertManager: AlertManager) {
        self.alertManager = alertManager
    }
    
    // MARK: - PKCE Helpers
    private func generateCodeVerifier() -> String {
        let length = 128
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in chars.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hashed = SHA256.hash(data: data)
        let base64 = Data(hashed).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return base64
    }
    
    // MARK: - Build the Spotify Authorization URL
    func makeAuthorizationURL() -> URL? {
        let newVerifier = generateCodeVerifier()
        codeVerifierInMemory = newVerifier
        
        // Also store the verifier in Keychain, in case the app backgrounds mid-flow
        if let data = newVerifier.data(using: .utf8) {
            let status = KeychainManager.save(key: keyCodeVerifier, data: data)
            // If you want to track potential Keychain errors here:
            if status != errSecSuccess {
                alertManager.showAlert(
                    title: "Keychain Error",
                    message: "Failed saving PKCE verifier (status: \(status))"
                )
            }
        }
        
        let codeChallenge = generateCodeChallenge(from: newVerifier)
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")
        components?.queryItems = [
            .init(name: "client_id", value: SpotifyConfig.clientID),
            .init(name: "response_type", value: "code"),
            .init(name: "redirect_uri", value: SpotifyConfig.redirectURI),
            .init(name: "scope", value: SpotifyConfig.scopes.joined(separator: " ")),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge", value: codeChallenge),
            .init(name: "show_dialog", value: "false")
        ]
        return components?.url
    }
    
    // MARK: - Exchange the Authorization Code for Tokens
    func exchangeCodeForTokens(code: String) async {
        // Retrieve code verifier from Keychain if needed
        let storedVerifier = loadPKCEVerifier() ?? codeVerifierInMemory
        guard !storedVerifier.isEmpty else {
            alertManager.showAlert(title: "Error", message: "PKCE verifier not found.")
            return
        }
        
        let url = URL(string: SpotifyConfig.tokenEndpointURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        let bodyDict = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": SpotifyConfig.redirectURI,
            "client_id": SpotifyConfig.clientID,
            "code_verifier": storedVerifier
        ]
        req.httpBody = bodyDict
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                alertManager.showAlert(title: "Error", message: "Failed exchanging code (bad response).")
                return
            }
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            // 1) Store the Spotify tokens in Keychain
            storeTokens(from: tokenResponse)
            
            // 2) Attempt Firebase sign-in using the new Spotify access token
            let spotifyAccessToken = tokenResponse.access_token
            let firebaseSuccess = await FirebaseAuthManager.shared
                .signInWithSpotify(spotifyAccessToken: spotifyAccessToken,
                                   alertManager: alertManager)
            
            // If the Firebase sign-in fails, do NOT proceed with isLoggedIn
            guard firebaseSuccess else {
                alertManager.showAlert(title: "Error",
                                       message: "Firebase failed to sign-in.")
                return
            }
            
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            alertManager.showAlert(
                title: "Error",
                message: "Exchange code error: \(error.localizedDescription)"
            )
        }
    }
    
    // MARK: - Refresh Tokens if Needed
    @discardableResult
    func refreshIfNeeded() async -> Bool {
        guard let refreshToken = loadRefreshToken() else {
            return false
        }
        guard shouldRefresh else {
            await MainActor.run { isLoggedIn = true }
            return true
        }
        
        let url = URL(string: SpotifyConfig.tokenEndpointURL)!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        
        let bodyDict = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": SpotifyConfig.clientID
        ]
        req.httpBody = bodyDict
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                alertManager.showAlert(title: "Error", message: "Failed refreshing token (bad response).")
                return false
            }
            let tokenResp = try JSONDecoder().decode(TokenResponse.self, from: data)
            storeTokens(from: tokenResp)
            await MainActor.run { isLoggedIn = true }
            return true
        } catch {
            alertManager.showAlert(title: "Error", message: "Refresh token error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Logout (with Keychain + Firebase sign-out)
    func logout() {
        // 1) Remove tokens from Keychain (with error checks)
        let atStatus = KeychainManager.delete(key: keyAccessToken)
        if atStatus != errSecSuccess && atStatus != errSecItemNotFound {
            alertManager.showAlert(
                title: "Keychain Error",
                message: "Failed removing Spotify access token (status: \(atStatus))"
            )
        }
        
        let rtStatus = KeychainManager.delete(key: keyRefreshToken)
        if rtStatus != errSecSuccess && rtStatus != errSecItemNotFound {
            alertManager.showAlert(
                title: "Keychain Error",
                message: "Failed removing Spotify refresh token (status: \(rtStatus))"
            )
        }
        
        let pkceStatus = KeychainManager.delete(key: keyCodeVerifier)
        if pkceStatus != errSecSuccess && pkceStatus != errSecItemNotFound {
            alertManager.showAlert(
                title: "Keychain Error",
                message: "Failed removing PKCE verifier (status: \(pkceStatus))"
            )
        }
        
        // 2) Remove stored expiration date
        UserDefaults.standard.removeObject(forKey: keyExpirationDate)
        
        // 3) Sign out of Firebase, if using
        do {
            try Auth.auth().signOut()
        } catch {
            alertManager.showAlert(
                title: "Error",
                message: "Failed logging out of Firebase: \(error.localizedDescription)"
            )
        }
        
        // 4) Mark as logged out
        isLoggedIn = false
    }
    
    // MARK: - Store Tokens with OSStatus Checks
    private func storeTokens(from resp: TokenResponse) {
        // Save the Access Token
        if let atData = resp.access_token.data(using: .utf8) {
            let atStatus = KeychainManager.save(key: keyAccessToken, data: atData)
            if atStatus != errSecSuccess {
                alertManager.showAlert(
                    title: "Keychain Error",
                    message: "Failed saving Spotify access token (status: \(atStatus))"
                )
            }
        }
        
        // Save the Refresh Token (if present)
        if let rt = resp.refresh_token, let rtData = rt.data(using: .utf8) {
            let rtStatus = KeychainManager.save(key: keyRefreshToken, data: rtData)
            if rtStatus != errSecSuccess {
                alertManager.showAlert(
                    title: "Keychain Error",
                    message: "Failed saving Spotify refresh token (status: \(rtStatus))"
                )
            }
        }
        
        // Update expiration date
        let expiresSec = resp.expires_in ?? 3600
        let expDate = Date().addingTimeInterval(TimeInterval(expiresSec))
        UserDefaults.standard.set(expDate, forKey: keyExpirationDate)
    }
    
    // MARK: - Load PKCE Verifier
    private func loadPKCEVerifier() -> String? {
        guard let data = KeychainManager.load(key: keyCodeVerifier) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Load Refresh Token
    private func loadRefreshToken() -> String? {
        guard let data = KeychainManager.load(key: keyRefreshToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - Check if Token Expired
    private var isTokenExpired: Bool {
        guard let exp = UserDefaults.standard.object(forKey: keyExpirationDate) as? Date else {
            return true
        }
        // Refresh ~30s before actual expiration
        return Date() >= exp.addingTimeInterval(-30)
    }
    
    private var shouldRefresh: Bool {
        return isTokenExpired
    }
    
    // MARK: - Load Access Token for immediate calls
    func loadAccessToken() -> String? {
        guard let data = KeychainManager.load(key: keyAccessToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
