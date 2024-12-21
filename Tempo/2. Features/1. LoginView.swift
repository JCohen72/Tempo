//
//  LoginView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var appState: AppState
    
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
            
            Button("Continue with Spotify") {
                authenticateUser()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("LoginButton")
            
            Spacer()
        }
        .padding()
    }
    
    private func authenticateUser() {
        appState.push(.questionnaireOne)
    }
}
