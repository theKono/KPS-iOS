//
//  CoreAPIService.swift
//  KPS
//
import Moya

enum CoreAPIService {
    case login(keyId: String, token: String, server: Server)
    case logout(server: Server)
    case fetchArticle(articleId: String, server: Server)
    case fetchAudio(audioId: String, server: Server)
    
    case fetchRootCollection(server: Server)
    case fetchCollection(Id: String, isNeedParent: Bool, isNeedSiblings: Bool, server: Server)
}


extension CoreAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .login(_, _, let server), .logout(let server), .fetchArticle(_, let server), .fetchAudio(_, let server), .fetchRootCollection(let server), .fetchCollection(_, _, _, let server):
          return server.projectUrl
        }
    }
    var path: String {
        switch self {
        case .login(_, _, _), .logout(_):
            return "/sessions"
        case .fetchArticle(let articleId, _):
            return "/articles/\(articleId)"
        case .fetchAudio(let audioId, _):
            return "/content/\(audioId)"
        case .fetchRootCollection(_):
            return "/content"
        case .fetchCollection(let Id, _, _, _):
            return "/content/\(Id)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .login(_, _, _):
            return .put
        case .logout(_):
            return .delete
        case .fetchArticle(_, _), .fetchAudio(_, _), .fetchRootCollection(_), .fetchCollection(_, _, _, _):
            return .get
        }
    }
    var task: Task {
        switch self {
        case .logout(_), .fetchArticle(_, _), .fetchAudio(_, _), .fetchRootCollection(_): // Send no parameters
            return .requestPlain
        case .fetchCollection(_, let isNeedParent, let isNeedSibling, _):
            return .requestParameters(parameters: ["parent": isNeedParent, "siblings": isNeedSibling], encoding: URLEncoding.queryString)
        case .login(let keyId, let token, _):
            return .requestParameters(parameters: ["kid": keyId, "token": token], encoding: JSONEncoding.default)
        }
    }
    var sampleData: Data {
        switch self {
        case .login(_, _, _):
            return "{\"error\": \"null\", \"isNew\": false,\"kps_session\":\"testSessionToken\",\"puser\": {\"puid\": \"testUser\"}}".utf8Encoded
        case .logout(_):
            return "{\"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        case .fetchArticle(_, _):
            guard let url = Bundle.current.url(forResource: "articleContent", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchAudio(_, _):
            guard let url = Bundle.current.url(forResource: "audioContent", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
                    return Data()
                }
            return data
        default:
            return "{\"error\": \"null\", \"isNew\": false,\"kps_session\":\"testSessionToken\",\"puser\": {\"puid\": \"testUser\"}}".utf8Encoded
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
