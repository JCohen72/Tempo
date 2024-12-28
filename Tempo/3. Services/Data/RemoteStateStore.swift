//
//  RemoteStateStore.swift
//  Tempo
//
//  Created by Joey Cohen on 12/28/24.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

struct RemoteAppStateData: Codable {
    let currentStep: String
    let completedOnboarding: Bool
}

/// Manages reading/writing app state from Firestore.
/// (In your code, this is basically `FirebaseData`.)
final class RemoteStateStore {
    private let db = Firestore.firestore()
    
    func fetchUserState(uid: String) async throws -> RemoteAppStateData? {
        let docRef = db.collection("users")
            .document(uid)
            .collection("metadata")
            .document("appState")
        
        let snapshot = try await docRef.getDocument()
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let remote = try JSONDecoder().decode(RemoteAppStateData.self, from: jsonData)
        return remote
    }
    
    func saveUserState(uid: String, data: [String: Any]) async throws {
        let docRef = db.collection("users")
            .document(uid)
            .collection("metadata")
            .document("appState")
        
        try await docRef.setData(data, merge: true)
    }
}
