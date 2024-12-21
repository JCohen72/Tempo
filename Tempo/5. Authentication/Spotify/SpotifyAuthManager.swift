//
//  SpotifyAuthManager.swift
//  Tempo
//
//  Created by Joey Cohen on 12/21/24.
//

import SwiftUI
import CryptoKit

final class SpotifyAuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    
    private let keyAccessToken    = "SpotifyAccessToken"
    private let keyRefreshToken   = "SpotifyRefreshToken"
    private let keyExpirationDate = "SpotifyExpirationDate"
    private let keyCodeVerifier   = "SpotifyPKCE_verifier"

    let alertManager: AlertManager
    
    private var codeVerifierInMemory: String = ""
    
    init(alertManager: AlertManager) {
        self.alertManager = alertManager
    }
    
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
    
    func makeAuthorizationURL() -> URL? {
        let newVerifier = generateCodeVerifier()
        codeVerifierInMemory = newVerifier
        
        // Also store the verifier in Keychain, just in case the user backgrounds the app mid-flow
        if let data = newVerifier.data(using: .utf8) {
            KeychainManager.save(key: keyCodeVerifier, data: data)
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
            storeTokens(from: tokenResponse)
            await MainActor.run {
                self.isLoggedIn = true
            }
        } catch {
            alertManager.showAlert(title: "Error", message: "Exchange code error: \(error.localizedDescription)")
        }
    }
    
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
    
    func logout() {
        KeychainManager.delete(key: keyAccessToken)
        KeychainManager.delete(key: keyRefreshToken)
        KeychainManager.delete(key: keyCodeVerifier)
        UserDefaults.standard.removeObject(forKey: keyExpirationDate)
        isLoggedIn = false
    }
    
    private func storeTokens(from resp: TokenResponse) {
        if let atData = resp.access_token.data(using: .utf8) {
            KeychainManager.save(key: keyAccessToken, data: atData)
        }
        if let rt = resp.refresh_token, let rtData = rt.data(using: .utf8) {
            KeychainManager.save(key: keyRefreshToken, data: rtData)
        }
        let expiresSec = resp.expires_in ?? 3600
        let expDate = Date().addingTimeInterval(TimeInterval(expiresSec))
        UserDefaults.standard.set(expDate, forKey: keyExpirationDate)
    }
    
    private func loadPKCEVerifier() -> String? {
        guard let data = KeychainManager.load(key: keyCodeVerifier) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func loadRefreshToken() -> String? {
        guard let data = KeychainManager.load(key: keyRefreshToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private var isTokenExpired: Bool {
        guard let exp = UserDefaults.standard.object(forKey: keyExpirationDate) as? Date else {
            return true
        }
        // Refresh 30s before actual expiration
        return Date() >= exp.addingTimeInterval(-30)
    }
    
    private var shouldRefresh: Bool {
        return isTokenExpired
    }
    
    func loadAccessToken() -> String? {
        guard let data = KeychainManager.load(key: keyAccessToken) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
