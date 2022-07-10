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
        
        request(target: .fetchArticle(Id: articleId, isNeedParent: isNeedParent, isNeedSiblings: isNeedSiblings, server: KPSClient.config.baseServer), completion: completion)
        
    }

}
