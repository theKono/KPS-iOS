//
//  KPSAuth.swift
//  KPS
//
//  Created by mingshing on 2022/4/24.
//

import Foundation

public enum AuthApiError: Error, Equatable {
    case Network
    case ServerError(reason: String)
    
    public var description: String {
        switch self {
        case .Network:
            return "Network connection error"
        case .ServerError(let reason):
            return reason
        }
    }
}

public protocol KPSAuthType {
    
    func login(token: String, completion: @escaping(Result<KPSAuthCredential, AuthApiError>) -> ())
    
}

public enum KPSAuthEnv {
    
    case dev
    case stg
    case prd
    
    var baseUrl: String{
        switch self{
        case .dev:
            return "https://kps-auth-dev.thekono.com/api/v1/"
        case .stg:
            return "https://kps-auth-stg.thekono.com/api/v1/"
        case .prd:
            return "https://kps-auth.thekono.com/api/v1/"
        }
    }
    
    
}

public class KPSAuth: KPSAuthType {
    
    
    private var serverUrl: String
    
    public init(appId: String, env: KPSAuthEnv) {
        self.serverUrl = env.baseUrl + "/projects/\(appId)"
    }
    public func login(token: String, completion: @escaping(Result<KPSAuthCredential, AuthApiError>) -> ()) {
        
        AuthAPIServiceProvider.request(.login(token: token, serverUrl: serverUrl)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let response = try JSONDecoder().decode(KPSAuthResonse.self, from: filteredResponse.data)
                    guard let credential = response.credential else {
                        completion(.failure(AuthApiError.ServerError(reason: response.error ?? "no server response")))
                        return
                    }
                    completion(.success(credential))
                } catch _ {
                   
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    completion(.failure(AuthApiError.ServerError(reason: errorResponse)))
                }
            case .failure(_):
                completion(.failure(AuthApiError.Network))
            }
        }
    }
}
