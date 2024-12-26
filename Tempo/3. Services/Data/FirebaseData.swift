//
//  FirebaseData.swift
//  Tempo
//
//  Created by Joey Cohen on 12/26/24.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

/**
 Represents the data structure stored in Firestore for the user's current app state.
 */
struct RemoteAppStateData: Codable {
    let currentStep: String
    let completedOnboarding: Bool
}

/**
 Handles reading/writing "appState" data in Firestore.
 For more advanced logic (e.g. merges, partial updates),
 you can expand these methods or add new ones.
 */
final class FirebaseData {
    
    /// A reference to the Firestore database
    private let db = Firestore.firestore()
    
    /**
     Attempts to fetch the user's appState document from Firestore.
     - Parameter uid: The user's unique Firebase Auth UID.
     - Returns: A `RemoteAppStateData` if found, or `nil` if the doc doesn't exist.
     - Throws: An error if the network call fails or decoding fails.
     */
    func fetchUserState(uid: String) async throws -> RemoteAppStateData? {
        let docRef = db.collection("users")
            .document(uid)
            .collection("metadata")
            .document("appState")
        
        let snapshot = try await docRef.getDocument()
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
        }
        
        // Convert Firestore dictionary -> JSON -> decode as `RemoteAppStateData`
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let remote = try JSONDecoder().decode(RemoteAppStateData.self, from: jsonData)
        return remote
    }
    
    /**
     Saves the given dictionary to Firestore under `appState`.
     - Parameter uid: The user's unique Firebase Auth UID.
     - Parameter data: A dictionary of fields to store (e.g. currentStep, completedOnboarding).
     - Throws: Error if the network call fails.
     */
    func saveUserState(uid: String, data: [String: Any]) async throws {
        let docRef = db.collection("users")
            .document(uid)
            .collection("metadata")
            .document("appState")
        
        try await docRef.setData(data, merge: true)
    }
}
