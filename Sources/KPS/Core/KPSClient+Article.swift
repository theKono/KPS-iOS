//
//  KPSClient+Article.swift
//  KPS
//
//  Created by Kono on 2022/5/27.
//

import Foundation
import Moya

// MARK: Article Related API
extension KPSClient {

    public func fetchArticleContent(Id articleId: String, isNeedParent: Bool = false, isNeedSiblings: Bool = false, completion: @escaping(Result<KPSArticle, MoyaError>) -> ()) {
        
        let resultClosure: ((Result<KPSArticle, MoyaError>) -> Void) = { result in
            
            switch result {
            case .success:
                completion(result)
                
            case let .failure(error):
                guard let errorResponse = error.response else { return }
                if (401..<404) ~= errorResponse.statusCode {
                    do {
                        var errorStateContent = try JSONDecoder().decode(KPSArticle.self, from: errorResponse.data)
                        switch errorResponse.statusCode {
                        case 401:
                            errorStateContent.error = .needLogin
                        case 402:
                            errorStateContent.error = .needPurchase
                        case 403:
                            errorStateContent.error = .userBlocked
                        default:
                            break
                        }
                        completion(.success(errorStateContent))
                        return
                    } catch _ {
                        
                    }
                }
                completion(.failure(error))
            }
        }
        
        request(target: .fetchArticle(Id: articleId, isNeedParent: isNeedParent, isNeedSiblings: isNeedSiblings, server: KPSClient.config.baseServer), completion: resultClosure)
    }

}
