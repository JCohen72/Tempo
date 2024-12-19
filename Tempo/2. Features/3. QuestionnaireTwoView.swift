//
//  3. QuestionnaireTwoView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

/// Second questionnaire screen for finalizing preferences.
/// Includes a "Back" button to return to QuestionnaireOneView and a "Done" button to proceed to MainView.
struct QuestionnaireTwoView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Questionnaire - Step 2")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Finalize your preferences here.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            // Insert the second step of the questionnaire controls here...
            
            HStack {
                Button("Back") {
                    withAnimation {
                        appState.step = .questionnaireOne
                    }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("BackToQ1Button")
                
                Spacer()
                
                Button("Done") {
                    finishOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("DoneButtonQ2")
            }
        }
        .padding()
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                               removal: .move(edge: .leading).combined(with: .opacity)))
    }
    
    /// Simulates saving preferences and transitioning to the main view.
    /// In production, integrate data persistence (Firebase, local cache, etc.) here.
    private func finishOnboarding() {
        withAnimation {
            appState.step = .main
        }
    }
}
