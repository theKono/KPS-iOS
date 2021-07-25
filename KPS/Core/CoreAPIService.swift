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
          return server.baseUrl
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
            return "{\"error\": \"null\", \"isNew\": false,\"kps_session\":\"s:02yyUyzMnVKJ3K2EH6mN11lDDNQZlDWO.yHaCOzniJX0SINUKR1XVz4vH+UUdOGEu7jl9h9GtJIw\",\"puser\": {\"puid\": \"testNewPili0\"}".utf8Encoded
        case .logout(_), .fetchFolders(_), .fetchArticle(_, _):
            return "{\"first_name\": \"Harry\", \"last_name\": \"Potter\"}".utf8Encoded
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
/*
use json file as sample data
     
     case .showAccounts:
         // Provided you have a file named accounts.json in your bundle.
         guard let url = Bundle.main.url(forResource: "accounts", withExtension: "json"),
             let data = try? Data(contentsOf: url) else {
                 return Data()
         }
         return data
     }
     
*/

}
// MARK: - Helpers
private extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}
