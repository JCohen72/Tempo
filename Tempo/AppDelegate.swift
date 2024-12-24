//
//  AppDelegate.swift
//  Tempo
//
//  Created by Joey Cohen on 12/24/24.
//

import SwiftUI
import FirebaseCore

/**
 Handles low-level application lifecycle events
 and configures Firebase on app startup.
 */
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
