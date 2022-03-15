//
//  IdentityManager.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//

import Foundation

class IdentityManager {


    internal static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#
    private var serverUrl: String
    init(serverUrl: String) {
        self.serverUrl = serverUrl
    }

    static func generateRandomID() -> String {
        "$KPSAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }
}
