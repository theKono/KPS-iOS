//
//  CoreAPIService.swift
//  KPS
//
import Moya

enum CoreAPIService {
    case login(keyId: String, token: String, server: Server)
    case logout(server: Server)
    case fetchFolders(server: Server)
    case fetchArticle(articleId: String, server: Server)
}


extension CoreAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .login(_, _, let server), .logout(let server), .fetchFolders(let server), .fetchArticle(_, let server):
          return server.projectUrl
        }
    }
    var path: String {
        switch self {
        case .login(_, _, _), .logout(_):
            return "/sessions"
        case .fetchFolders(_):
            return "/folders"
        case .fetchArticle(let articleId, _):
            return "/articles/\(articleId)"
        }
    }
    var method: Moya.Method {
        switch self {
        case .login(_, _, _):
            return .put
        case .logout(_):
            return .delete
        case .fetchFolders(_), .fetchArticle(_, _):
            return .get
        }
    }
    var task: Task {
        switch self {
        case .logout(_), .fetchFolders(_), .fetchArticle(_, _): // Send no parameters
            return .requestPlain
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
        case .fetchFolders(_):
            guard let url = Bundle.current.url(forResource: "folderList", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchArticle(_, _):
            guard let url = Bundle.current.url(forResource: "articleContent", withExtension: "json"),
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
