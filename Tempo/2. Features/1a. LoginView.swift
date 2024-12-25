//
//  LoginView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI
import AuthenticationServices

/// This file contains only the view (UI) code. All
/// logic to start or handle Spotify auth is delegated
/// to `LoginViewLogic`.
struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var authManager: AuthManager
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
                Task {
                    await startSpotifyAuth()
                }
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
    }
    
    /// Delegates the actual Spotify Authentication Session
    /// to the LoginViewLogic struct, passing the necessary
    /// environment objects and state bindings.
    private func startSpotifyAuth() async {
        await LoginViewModel.startSpotifyAuth(
            authManager: authManager,
            alertManager: alertManager,
            isLoading: $isLoading,
            contextProvider: contextProvider
        )
    }
}
