//
//  3. QuestionnaireTwoView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

struct QuestionnaireTwoView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Questionnaire - Step 2")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Finalize your preferences here.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
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
            .padding(.horizontal)
        }
        .padding()
    }
    
    private func finishOnboarding() {
        withAnimation {
            appState.step = .main
        }
    }
}
