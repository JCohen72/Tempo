//
//  QuestionnaireOneView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

/// First questionnaire screen to gather initial user preferences.
/// Provides a "Next" button that transitions to QuestionnaireTwoView.
struct QuestionnaireOneView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Questionnaire - Step 1")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Select your preferred genres or provide some details.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            // Insert form elements or selection controls here...
            
            HStack {
                Spacer()
                Button("Next") {
                    withAnimation {
                        appState.step = .questionnaireTwo
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("NextFromQ1Button")
            }
        }
        .padding()
        .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                               removal: .move(edge: .leading).combined(with: .opacity)))
    }
}
