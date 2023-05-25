//
//  KPSClient+Search.swift
//  KPS
//
//  Created by Kono on 2023/5/10.
//

import Foundation
import Moya

// MARK: Search Related API
extension KPSClient {
    public func search(with keyword: String, completion: @escaping(Result<KPSSearch, MoyaError>) -> ()) {
        
        let resultClosure: ((Result<KPSSearch, MoyaError>) -> Void) = { result in
            
            switch result {
            case .success:
                completion(result)
                
            case .failure(let error):
                
                guard let errorResponse = error.response else { return }
                do {
                    let errorStateContent = try JSONDecoder().decode(KPSSearch.self, from: errorResponse.data)
                    completion(.success(errorStateContent))
                    return
                } catch _ {
                    
                }
                completion(.failure(error))
            }
        }
        
        request(target: .search(keyword: keyword, server: KPSClient.config.baseServer), completion: resultClosure)
    }
}
