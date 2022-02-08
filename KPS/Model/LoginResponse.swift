//
//  LoginResponse.swift
//  KPS
//

// MARK: - LoginResponse
public struct LoginResponse: Codable {
    let isNew: Bool
    let kpsSession: String
    let user: KPSUser

    enum CodingKeys: String, CodingKey {
        case isNew
        case kpsSession = "kps_session"
        case user = "puser"
    }
}
public struct KPSUser: Codable {
    
    let id: String
    let status: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "puid"
        case status
    }
}


