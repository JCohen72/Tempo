//
//  TokenResponse.swift
//  Tempo
//
//  Created by Joey Cohen on 12/21/24.
//

import SwiftUI

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let scope: String?
    let expires_in: Int?
    let refresh_token: String?
}
