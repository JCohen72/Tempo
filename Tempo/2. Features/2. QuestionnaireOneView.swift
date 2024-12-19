//
//  QuestionnaireOneView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

struct QuestionnaireOneView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Questionnaire - Step 1")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Select your preferred genres or provide some details.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
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
            .padding(.horizontal)
        }
        .padding()
    }
}
