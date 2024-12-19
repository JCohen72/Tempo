//
//  4. MainView.swift
//  Tempo
//
//  Created by Joey Cohen on 12/18/24.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Main App View")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
                .accessibilityIdentifier("MainView")
            Spacer()
        }
    }
}
