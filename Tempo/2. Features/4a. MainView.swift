//
//  4. MainView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject private var authManager: SpotifyAuthManager
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack {
            Spacer()
            Text("Main App View")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            Button("Logout") {
                authManager.logout()
                appState.popToRoot()
                
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .navigationBarBackButtonHidden(true)
    }
}
