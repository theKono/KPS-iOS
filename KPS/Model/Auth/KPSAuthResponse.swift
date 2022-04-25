//
//  KPSAuthResponse.swift
//  KPS
//
//  Created by mingshing on 2022/4/25.
//

import Foundation

struct KPSAuthResonse: Codable {
    
    var error: String?
    var puid: String?
    var credential: KPSAuthCredential?
    
    enum CodingKeys: String, CodingKey {
        case error
        case puid
        case credential = "kps"
    }
}
