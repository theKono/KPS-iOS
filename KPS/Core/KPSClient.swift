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
    /// KPSClient.config = .init(apiKey: "API_KEY", appId: "APP_ID")

    public static let shared = Client(apiKey: Client.config.apiKey, appId: Client.config.appId)
    
    
    init(apiKey: String, appId: String, networkProvider: NetworkProvider? = nil) {
        
        self.apiKey = apiKey
        self.appId = appId
        
        if let networkProvider = networkProvider {
            self.networkProvider = networkProvider
        } else {
            self.networkProvider =
                NetworkProvider(plugins: [NetworkLoggerPlugin()])
        }
    }
    
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
    
    public func fetchArticle(articleId: String, completion: @escaping(Result<KPSContent, Error>) -> ()) {
        
        let resultClosure: ((Result<KPSContent, Error>) -> Void) = { result in
            
            switch result {
            case let .success(response):
                var content = response
                content.images = response.images.map {
                    var mutableImage = $0
                    mutableImage.baseURL = Client.config.baseServer.baseUrl.absoluteString
                    return mutableImage
                }
                completion(.success(content))
                
            case let .failure(error):
                completion(.failure(error))
            }
        }
        request(target:.fetchArticle(articleId: articleId, server: Client.config.baseServer), completion: resultClosure)
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
        
        /// Setup a configuration for the shared Instance `Client`.
        ///
        /// - Parameters:
        ///     - apiKey: the KPS API key
        ///     - appId: the KPS project id
        ///     - server: the KPS backend server setting
        public init(apiKey: String = "", appId: String) {
            self.init(apiKey: apiKey,
                      appId: appId,
                      server: nil)
        }
        
        init(apiKey: String, appId: String, server: Server?) {
            self.apiKey = apiKey
            self.appId = appId
            
            if let baseServer = server {
                self.baseServer = baseServer
            } else {
                self.baseServer = .prod(appId: appId, version: "1")
            }
        }
    }
}


enum Server {
    case develop(appId: String, version: String)
    case staging(appId: String, version: String)
    case prod(appId: String, version: String)
  
    var baseUrl: URL {
        switch self {
        case .develop(_, let version):
            return URL(string: "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(version)")!
        case .staging(_, let version):
            return URL(string: "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(version)")!
        case .prod(_, let version):
            return URL(string: "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(version)")!
        }
    }
    
    var projectUrl: URL {
        switch self {
        case .develop(let appId, _), .staging(let appId, _), .prod(let appId, _):
            return baseUrl.appendingPathComponent("/projects/\(appId)")
        }
    }
}
