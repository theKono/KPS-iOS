//
//  LoginResponse.swift
//  KPS
//

// MARK: - LoginResponse
public struct LoginResponse: Codable {
    public let isNew: Bool
    public let kpsSession: String
    let user: KPSUserModel

    enum CodingKeys: String, CodingKey {
        case isNew
        case kpsSession = "kps_session"
        case user = "puser"
    }
}
struct SessionResponse: Codable {
    var puser: KPSUserModel?
}

public struct KPSUserModel: Codable {
    
    public let id: String
    public let status: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "puid"
        case status
    }
}

public struct PermissionResponse {
    
    enum CodingKeys: String, CodingKey {
        case error, permissions
    }
    public var error: String?
    public var permissions: [String: Any]?
}

extension PermissionResponse: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        permissions = try container.decodeIfPresent([String: Any].self, forKey: .permissions)
        
    }

}
