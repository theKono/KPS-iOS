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
    
    case fetchAudio(audioId: String, isNeedParent: Bool, isNeedSiblings: Bool, server: Server)
    
    case fetchRootCollection(server: Server)
    case fetchCollection(Id: String, isNeedParent: Bool, isNeedSiblings: Bool, server: Server)
    case fetchCollectionWithPaging(Id: String, isNeedParent: Bool, isNeedSiblings: Bool, startChildOrderInParent: Int?, startChildId: String?, server: Server)
    
    case fetchLeafNodeFromRootNode(Id: String, startFlatOrder: Int?, startId: String?, reverse: Bool, server: Server)
    
    case fetchArticle(Id: String, isNeedParent: Bool, isNeedSiblings: Bool, server: Server)
    
    case updateFCMToken(token: String, server: Server)
    
    case search(keyword: String, server: Server)
}


extension CoreAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .login(_, _, let server), .logout(let server), .fetchUserPermission(let server), .fetchCurrentUser(let server), .fetchAudio(_, _, _, let server), .fetchRootCollection(let server), .fetchCollection(_, _, _, let server), .fetchArticle(_, _, _, let server), .updateFCMToken(_, let server), .search(_, let server), .fetchLeafNodeFromRootNode(_, _, _, _, let server):
            return server.projectUrl
            
        case .fetchCollectionWithPaging(_, _, _, _, _, let server):
            return server.projectUrl(version: .v2)
            
        }
    }
    var path: String {
        switch self {
        case .login(_, _, _), .logout(_), .fetchCurrentUser(_):
            return "/sessions"
        case .fetchUserPermission(_):
            return "/puser_permissions"
        case .fetchAudio(let audioId, _, _, _):
            return "/content/\(audioId)"
        case .fetchRootCollection(_):
            return "/content"
        case .fetchCollection(let Id, _, _, _):
            return "/content/\(Id)"
        case .fetchCollectionWithPaging(let Id, _, _, _, _, _):
            return "/content/\(Id)"
        case .fetchLeafNodeFromRootNode(let Id, _, _, _, _):
            return "/leafNodes/\(Id)"
        case .fetchArticle(let Id, _, _, _):
            return "/content/\(Id)"
        case .updateFCMToken(_, _):
            return "/pushTokens"
        case .search(_, _):
            return "/search"
        }
    }
    var method: Moya.Method {
        switch self {
        case .login(_, _, _), .updateFCMToken(_, _):
            return .put
        case .logout(_):
            return .delete
        case .fetchCurrentUser(_), .fetchUserPermission(_), .fetchAudio(_, _, _, _), .fetchRootCollection(_), .fetchCollection(_, _, _, _), .fetchCollectionWithPaging(_, _, _, _, _, _), .fetchLeafNodeFromRootNode(_, _, _, _, _), .fetchArticle(_, _, _, _), .search(_, _):
            return .get
        }
    }
    var task: Task {
        //query string only accept literal boolean
        let queryEncoding = URLEncoding(destination: .queryString, boolEncoding: .literal)
        
        switch self {
        case .logout(_), .fetchCurrentUser(_), .fetchUserPermission(_), .fetchRootCollection(_): // Send no parameters
            return .requestPlain
        case .fetchAudio(_, let isNeedParent, let isNeedSibling, _):
            return .requestParameters(parameters: ["parent": isNeedParent, "siblings": isNeedSibling], encoding: queryEncoding)
        case .fetchCollection(_, let isNeedParent, let isNeedSibling, _):
            return .requestParameters(parameters: ["parent": isNeedParent, "siblings": isNeedSibling], encoding: queryEncoding)
        case .fetchCollectionWithPaging(_, let isNeedParent, let isNeedSibling, let startChildOrderInParent, let startChildId, _):
            var paramDic: [String : Any] = ["parent": isNeedParent, "siblings": isNeedSibling]
            paramDic["startChildOrderInParent"] = startChildOrderInParent
            paramDic["startChildId"] = startChildId
            return .requestParameters(parameters: paramDic, encoding: queryEncoding)
        case .fetchLeafNodeFromRootNode(_, let startFlatOrder, let startId, let reverse, _):
            var paramDic: [String : Any] = ["reverse": reverse]
            paramDic["startFlatOrder"] = startFlatOrder
            paramDic["startId"] = startId
            return .requestParameters(parameters: paramDic, encoding: queryEncoding)
        case .fetchArticle(_, let isNeedParent, let isNeedSibling, _):
            return .requestParameters(parameters: ["parent": isNeedParent, "siblings": isNeedSibling], encoding: queryEncoding)
        case .login(let keyId, let token, _):
            return .requestParameters(parameters: ["kid": keyId, "token": token], encoding: JSONEncoding.default)
        case .updateFCMToken(let token, _):
            return .requestParameters(parameters: ["pushToken" : token], encoding: JSONEncoding.default)
        case .search(let keyword, _):
            return .requestParameters(parameters: ["keyword" : keyword], encoding: queryEncoding)
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
        case .fetchCollection(_, _, _, _), .fetchCollectionWithPaging(_, _, _, _, _, _):
            guard let url = Bundle.resourceBundle.url(forResource: "folderContent", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchLeafNodeFromRootNode(_, let startFlatOrder, let startId, let reverse, _):
            guard let url = Bundle.resourceBundle.url(forResource: "leafNodes", withExtension: "json"),
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
        case .fetchAudio(let audioId, _, _, _):
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
        case .updateFCMToken(_, _):
            return "{\"error\": \"null\"}".utf8Encoded
        case .search(_, _):
            guard let url = Bundle.resourceBundle.url(forResource: "searchResult", withExtension: "json"),
                  let data = try? Data(contentsOf: url)
            else {
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
