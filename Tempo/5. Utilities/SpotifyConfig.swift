//
//  SpotifyConfig.swift
//  Tempo
//
//  Created by Joey Cohen on 12/21/24.
//

import SwiftUI

struct SpotifyConfig {
    static let clientID = "56ec58b63f7247f5aa3324de6aecfdc0"
    static let redirectURI = "tempo://spotify-callback"
    static let tokenEndpointURL = "https://accounts.spotify.com/api/token"
    
    static let scopes: [String] = [
        "user-read-private",
        "user-read-email",
        "playlist-read-private",
        "playlist-modify-private",
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "streaming"
    ]
}
