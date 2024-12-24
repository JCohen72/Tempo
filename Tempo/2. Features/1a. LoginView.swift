//
//  LoginView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: SpotifyAuthManager
    @EnvironmentObject private var alertManager: AlertManager
    
    @State private var isLoading = false
    private let contextProvider = AuthPresentationContextProvider()

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Welcome to MyMusicApp")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please log in with Spotify to continue.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
            
            // Button that triggers Spotify PKCE flow
            Button(action: {
                guard !isLoading else { return }
                isLoading = true
                Task { await authenticateUser() }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding(.trailing, 4)
                        Text("Connecting...")
                    } else {
                        Text("Continue with Spotify")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)
            .accessibilityIdentifier("LoginButton")
            
            Spacer()
        }
        .padding()
        // Present alerts
        .alert(item: $alertManager.alertMessage) { alertData in
            Alert(
                title: Text(alertData.title),
                message: Text(alertData.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    /// Start PKCE authentication with Spotify.
    private func authenticateUser() async {
        guard let authURL = authManager.makeAuthorizationURL() else {
            alertManager.showAlert(title: "Error", message: "Could not create authorization URL.")
            isLoading = false
            return
        }
        
        let scheme = (SpotifyConfig.redirectURI as NSString).components(separatedBy: "://").first ?? ""
        
        // Create the ASWebAuthenticationSession
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: scheme) { callbackURL, error in
            
            // iOS 17+ refined error handling
            if #available(iOS 17.0, *) {
                if let sessionError = error as? ASWebAuthenticationSessionError {
                    switch sessionError.code {
                    case .canceledLogin:
                        self.alertManager.showAlert(title: "Login Canceled", message: "You canceled the Spotify login.")
                        self.isLoading = false
                        return
                    default:
                        self.alertManager.showAlert(title: "Login Error", message: sessionError.localizedDescription)
                        self.isLoading = false
                        return
                    }
                }
            } else {
                // Fallback for iOS 13–16
                if let nsError = error as NSError?, nsError.domain == ASWebAuthenticationSessionErrorDomain,
                   nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    self.alertManager.showAlert(title: "Login Canceled", message: "You canceled the Spotify login.")
                    self.isLoading = false
                    return
                } else if let error = error {
                    self.alertManager.showAlert(title: "Login Error", message: error.localizedDescription)
                    self.isLoading = false
                    return
                }
            }
            
            // Parse the code from callback
            guard
                let successURL = callbackURL,
                let queryItems = URLComponents(string: successURL.absoluteString)?.queryItems,
                let codeItem = queryItems.first(where: { $0.name == "code" }),
                let code = codeItem.value
            else {
                self.alertManager.showAlert(title: "Error", message: "No ‘code’ parameter found in callback.")
                self.isLoading = false
                return
            }
        
            // Exchange the code for tokens
            Task {
                await self.authManager.exchangeCodeForTokens(code: code)
                // We do NOT navigate here; we let AppFlowCoordinator respond to isLoggedIn changes
                // Done or error by the time it returns
                self.isLoading = false
            }
        }
        
        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = contextProvider
        session.start()
    }
}
