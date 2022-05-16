//
//  AuthAPIService.swift
//  KPS
//
//  Created by mingshing on 2022/4/24.
//

import Moya

let AuthAPIServiceProvider = MoyaProvider<AuthAPIService>()
//let AuthAPIServiceProvider = MoyaProvider<AuthAPIService>(stubClosure: MoyaProvider.delayedStub(0.2))
//let AuthAPIServiceProvider = MoyaProvider<AuthAPIService>(stubClosure: MoyaProvider.immediatelyStub)
                                                                                   
enum AuthAPIService {
    
    case login(token: String, serverUrl: String)
    case fetchCurrentSession(serverUrl: String)
    case logout(serverUrl: String)

}

extension AuthAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .login(_, let serverUrl), .fetchCurrentSession(let serverUrl), .logout(let serverUrl):
            return URL(string: serverUrl)!
        }
    }
    
    var path: String {
        switch self {
        case .login, .fetchCurrentSession, .logout:
            return "sessions"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .login:
            return .put
        case .fetchCurrentSession:
            return .get
        case .logout:
            return .delete
        }
    }
    
    var sampleData: Data {
        switch self {
        case .login, .fetchCurrentSession, .logout:
            return Data()
        }
    }
    
    var task: Task {
        switch self {
        case .login(let token, _):
            return .requestParameters(parameters: ["token": token], encoding: JSONEncoding.default)
        case .fetchCurrentSession, .logout:
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
