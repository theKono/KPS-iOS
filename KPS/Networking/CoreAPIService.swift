//
//  CoreAPIService.swift
//  KPS
//
import Moya

enum CoreAPIService {
    case login(keyId: String, token: String, server: Server)
    case logout(server: Server)
    case fetchCurrentUser(server: Server)
    case fetchUserPermission(server: Server)
    
    case fetchAudio(audioId: String, server: Server)
    
    case fetchRootCollection(server: Server)
    case fetchCollection(Id: String, isNeedParent: Bool, isNeedSiblings: Bool, server: Server)
    
    case fetchArticle(Id: String, isNeedParent: Bool, isNeedSiblings: Bool, server: Server)
}


extension CoreAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .login(_, _, let server), .logout(let server), .fetchUserPermission(let server), .fetchCurrentUser(let server), .fetchAudio(_, let server), .fetchRootCollection(let server), .fetchCollection(_, _, _, let server), .fetchArticle(_, _, _, let server):
          return server.projectUrl
        }
    }
    var path: String {
        switch self {
        case .login(_, _, _), .logout(_), .fetchCurrentUser(_):
            return "/sessions"
        case .fetchUserPermission(_):
            return "/puser_permissions"
        case .fetchAudio(let audioId, _):
            return "/content/\(audioId)"
        case .fetchRootCollection(_):
            return "/content"
        case .fetchCollection(let Id, _, _, _):
            return "/content/\(Id)"
        case .fetchArticle(let Id, _, _, _):
            return "/content/\(Id)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .login(_, _, _):
            return .put
        case .logout(_):
            return .delete
        case .fetchCurrentUser(_), .fetchUserPermission(_), .fetchAudio(_, _), .fetchRootCollection(_), .fetchCollection(_, _, _, _), .fetchArticle(_, _, _, _):
            return .get
        }
    }
    var task: Task {
        switch self {
        case .logout(_), .fetchCurrentUser(_), .fetchUserPermission(_), .fetchAudio(_, _), .fetchRootCollection(_): // Send no parameters
            return .requestPlain
        case .fetchCollection(_, let isNeedParent, let isNeedSibling, _):
            return .requestParameters(parameters: ["parent": isNeedParent, "siblings": isNeedSibling], encoding: URLEncoding.queryString)
        case .fetchArticle(_, let isNeedParent, let isNeedSibling, _):
            return .requestParameters(parameters: ["parent": isNeedParent, "siblings": isNeedSibling], encoding: URLEncoding.queryString)
        case .login(let keyId, let token, _):
            return .requestParameters(parameters: ["kid": keyId, "token": token], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .login(_, _, _):
            return "{\"error\": \"null\", \"isNew\": false,\"kps_session\":\"testSessionToken\",\"puser\": {\"puid\": \"testUser\", \"status\": 1}}".utf8Encoded
        case .logout(_):
            return "{\"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        case .fetchCurrentUser(_):
            return "{\"puser\": {\"puid\": \"testUser\", \"status\": 1}}".utf8Encoded
        case .fetchUserPermission(_):
            guard let url = Bundle.resourceBundle.url(forResource: "userPermission", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchRootCollection(_):
            guard let url = Bundle.current.url(forResource: "rootCollection", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchCollection(_, _, _, _):
            guard let url = Bundle.resourceBundle.url(forResource: "folderContent", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchArticle(let articleId, _, _, _):
            var resFileName: String
            if articleId == "articleContentWithWrongArticleId" {
                resFileName = "articleContentWithWrongArticleId"
            } else if articleId == "articleContentWithoutPermission" {
                resFileName = "articleContentWithoutPermission"
            } else {
                resFileName = "articleContent"
            }
            
            guard let url = Bundle.resourceBundle.url(forResource: resFileName, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchAudio(let audioId, _):
            var resFileName: String
            if audioId == "testTrack3" {
                resFileName = "audioContentWithWordTime"
            } else if audioId == "audioContentWithoutPermission" {
                resFileName = "audioContentWithoutPermission"
            } else {
                resFileName = "audioContent"
            }
            guard let url = Bundle.resourceBundle.url(forResource: resFileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
                    return Data()
                }
            return data
        }
        
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }

}
// MARK: - Helpers
internal extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}
