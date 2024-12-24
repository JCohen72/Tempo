//
//  AlertManager.swift
//  Tempo
//
//  Created by Joey Cohen on 12/21/24.
//

import SwiftUI

final class AlertManager: ObservableObject {
    @Published var alertMessage: AlertData?
    
    func showAlert(title: String, message: String) {
        self.alertMessage = AlertData(title: title, message: message)
    }
    
    struct AlertData: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
}
