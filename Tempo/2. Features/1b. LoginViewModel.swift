//
//  LoginViewModel.swift
//  Tempo
//
//  Created by Joey Cohen on 12/25/24.
//

import SwiftUI
import AuthenticationServices

/// Handles all non-UI logic from LoginView, keeping
/// the view itself lightweight. Production apps can
/// expand or unit-test this logic independently.
struct LoginViewModel {
    
    /// Responsible for launching an ASWebAuthenticationSession
    /// and exchanging the Spotify authorization code for tokens.
    @MainActor
    static func startSpotifyAuth(
        authManager: AuthManager,
        alertManager: AlertManager,
        isLoading: Binding<Bool>,
        contextProvider: ASWebAuthenticationPresentationContextProviding
    ) async {
        // 1) Construct the authorization URL
        guard let authURL = authManager.makeAuthorizationURL() else {
            alertManager.showAlert(title: "Error", message: "Could not create authorization URL.")
            isLoading.wrappedValue = false
            return
        }
        
        let scheme = (SpotifyConfig.redirectURI as NSString)
            .components(separatedBy: "://").first ?? ""
        
        // 2) Create & start an ASWebAuthenticationSession
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: scheme
        ) { callbackURL, error in
            
            // 2a) On iOS 17+, we handle refined errors:
            if #available(iOS 17.0, *) {
                if let sessionError = error as? ASWebAuthenticationSessionError {
                    switch sessionError.code {
                    case .canceledLogin:
                        alertManager.showAlert(
                            title: "Login Canceled",
                            message: "You canceled the Spotify login."
                        )
                        isLoading.wrappedValue = false
                        return
                    default:
                        alertManager.showAlert(
                            title: "Login Error",
                            message: sessionError.localizedDescription
                        )
                        isLoading.wrappedValue = false
                        return
                    }
                }
            } else {
                // 2b) Fallback for iOS 13–16:
                if let nsError = error as NSError?,
                   nsError.domain == ASWebAuthenticationSessionErrorDomain,
                   nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    alertManager.showAlert(
                        title: "Login Canceled",
                        message: "You canceled the Spotify login."
                    )
                    isLoading.wrappedValue = false
                    return
                } else if let error = error {
                    alertManager.showAlert(
                        title: "Login Error",
                        message: error.localizedDescription
                    )
                    isLoading.wrappedValue = false
                    return
                }
            }
            
            // 3) Extract the code from the callback URL
            guard
                let successURL = callbackURL,
                let queryItems = URLComponents(string: successURL.absoluteString)?.queryItems,
                let codeItem = queryItems.first(where: { $0.name == "code" }),
                let code = codeItem.value
            else {
                alertManager.showAlert(
                    title: "Error",
                    message: "No ‘code’ parameter found in callback."
                )
                isLoading.wrappedValue = false
                return
            }
            
            // 4) Exchange the code for tokens
            Task {
                await authManager.exchangeCodeForTokens(code: code)
                isLoading.wrappedValue = false
            }
        }
        
        session.prefersEphemeralWebBrowserSession = true
        session.presentationContextProvider = contextProvider
        
        // 5) Launch the authentication session
        session.start()
    }
}
