//
//  AppState.swift
//  Tempo
//
//  Created by Joey Cohen on 12/19/24.
//

import SwiftUI
import Combine

enum AppStep: Hashable {
    case login
    case questionnaireOne
    case questionnaireTwo
    case main
}

@MainActor
final class AppState: ObservableObject {
    @Published var step: AppStep = .login
    @Published var isLoggedIn: Bool = false
}
