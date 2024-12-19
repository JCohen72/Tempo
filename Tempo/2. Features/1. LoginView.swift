//
//  LoginView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

/// Login screen where the user authenticates with Spotify.
/// On success, transitions to QuestionnaireOneView.
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to MyMusicApp")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Please log in with Spotify to continue.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Continue with Spotify") {
                authenticateUser()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("LoginButton")
        }
        .padding()
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                               removal: .move(edge: .top).combined(with: .opacity)))
    }
    
    /// Simulates user authentication. In production, integrate the real Spotify Auth flow here.
    private func authenticateUser() {
        withAnimation {
            appState.isLoggedIn = true
            appState.step = .questionnaireOne
        }
    }
}
