//
//  KPSClient.swift
//  KPS
//


import Foundation
import UIKit
import Moya

typealias NetworkProvider = MoyaProvider<CoreAPIService>


public final class Client {
    let apiKey: String
    let appId: String
    
    private let networkProvider: NetworkProvider
   
    
    /// The current user id from the Token.
    public internal(set) var currentUserId: String?
    /// The current user.
    //public internal(set) var currentUser: UserProtocol?
    
    /// A configuration to initialize the shared Client.
    public static var config = Config(apiKey: "", appId: "")
    
    
    /// A shared client.
    /// - Note: Setup `KPSClient.config` before using a shared client.
    /// ```
    /// // Setup a shared client.
    /// KPSClient.config = .init(apiKey: "API_KEY", appId: "APP_ID", token: "TOKEN")

    public static let shared = Client(apiKey: Client.config.apiKey,
                                      appId: Client.config.appId,
                                      networkProvider: Client.config.networkProvider)
    
    
    private init(apiKey: String,
                 appId: String,
                 networkProvider: NetworkProvider? = nil) {
        
        self.apiKey = apiKey
        self.appId = appId
        
        //networkAuthorization = AuthorizationMoyaPlugin()
        
        if let networkProvider = networkProvider {
            self.networkProvider = networkProvider
        } else {
            self.networkProvider =
                NetworkProvider(plugins: [NetworkLoggerPlugin()])
        }
        
    }
    /*
    case login(keyId: String, token: String, server: Server)
    case logout(server: Server)
    case fetchFolders(server: Server)
    case fetchArticle(articleId: String, server: Server)
    */
    
    public func login(keyID: String, token: String, completion: @escaping (Result<LoginResponse, Error>) -> ()) {
        request(target:.login(keyId: keyID, token: token, server: Client.config.baseServer) , completion: completion)
    }
    
    public func logout(completion: @escaping(Result<Moya.Response, Error>) -> ()) {
        networkProvider.request(.logout(server: Client.config.baseServer)) { result in
            switch result {
            case let .success(response):
                do {
                    let data = try response.mapJSON()
                    print(data)
                } catch _ {
                    print("decode error")
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchFolders(completion: @escaping(Result<Moya.Response, MoyaError>) -> ()) {
        //request(target:.fetchFolders(server: Client.config.baseServer) , completion: completion)
        networkProvider.request(.fetchFolders(server: Client.config.baseServer)) { result in
            switch result {
            case let .success(response):
                do {
                    let data = try response.mapJSON()
                    print(data)
                } catch _ {
                    print("decode error")
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    public func fetchArticle(articleId: String, completion: @escaping(Result<Moya.Response, MoyaError>) -> ()) {
        //request(target:.fetchFolders(server: Client.config.baseServer) , completion: completion)
        networkProvider.request(.fetchArticle(articleId: articleId, server: Client.config.baseServer)) { result in
            switch result {
            case let .success(response):
                do {
                    let data = try response.mapJSON()
                    print(data)
                } catch _ {
                    print("decode error")
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
        
}


extension Client {
    private func request<T: Decodable>(target: CoreAPIService, completion: @escaping (Result<T, Error>) -> ()) {
        networkProvider.request(target) { result in
            switch result {
            case let .success(response):
                do {
                    let results = try JSONDecoder().decode(T.self, from: response.data)
                    completion(.success(results))
                } catch let error {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}


// MARK: - Config
extension Client {
    /// A configuration for the shared Instance `Client`.
    public struct Config {
        let apiKey: String
        let appId: String
        let baseServer: Server
        let networkProvider: NetworkProvider?
        
        /// Setup a configuration for the shared Instance `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: the KPS API key
        ///     - appId: the KPS project id

        public init(apiKey: String = "",
                    appId: String) {
            self.init(apiKey: apiKey,
                      appId: appId,
                      networkProvider: nil)
        }
        
        init(apiKey: String,
             appId: String,
             networkProvider: NetworkProvider?) {
            self.apiKey = apiKey
            self.appId = appId
            self.baseServer = .develop(appId: appId, version: "1")
            self.networkProvider = networkProvider
        }
    }
}


enum Server {
    case develop(appId: String, version: String)
    case staging(appId: String, version: String)
    case prod(appId: String, version: String)
  
    var baseUrl: URL {
        switch self {
        case .develop(let appId, let version):
            return URL(string: "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(version)/projects/\(appId)")!
        case .staging(let appId, let version):
            return URL(string: "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(version)/projects/\(appId)")!
        case .prod(let appId, let version):
            return URL(string: "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(version)/projects/\(appId)")!
        }
    }
}
