//
//  QuestionnaireTwoView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

struct QuestionnaireTwoView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Questionnaire - Step 2")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("Finalize your preferences here.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            HStack {
                Button("Back") {
                    appState.pop()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Done") {
                    finishOnboarding()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
    
    private func finishOnboarding() {
        appState.push(.main)
    }
}
