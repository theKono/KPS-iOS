//
//  KPSPurchaseProductManager.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//

import Foundation
import StoreKit

class ProductsRequestFactory {

    func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        return SKProductsRequest(productIdentifiers: productIdentifiers)
    }
}

// Note: Should we handle the fail product request?
// Add retry mechanism?
class KPSPurchaseProductManager: NSObject {
    
    typealias Callback = (Result<Set<SK1Product>, Error>) -> Void
    
    private let productsRequestFactory: ProductsRequestFactory
    private var completionHandlers: [Set<String>: [Callback]] = [:]
    private var purchaseItems: [Set<String>: Set<KPSPurchaseItem>] = [:]
    init(productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory()) {
        self.productsRequestFactory = productsRequestFactory
    }
    
    func sk1Products(withIdentifiers identifiers: Set<String>,
                     completion: @escaping Callback) {
        guard identifiers.count > 0 else {
            completion(.success([]))
            return
        }
        self.completionHandlers[identifiers, default: []].append(completion)
        
        let _ = self.startRequest(forIdentifiers: identifiers)
        
    }
    
    @discardableResult
    private func startRequest(forIdentifiers identifiers: Set<String>) -> SKProductsRequest {
        let request = self.productsRequestFactory.request(productIdentifiers: identifiers)
        request.delegate = self
        request.start()

        return request
    }
    
    public func products(withIdentifiers identifiers: [String],
                         useCache: Bool = true,
                  completion: @escaping (Result<Set<KPSPurchaseItem>, Error>) -> Void) {
        
        let uniqueIdentifier = Set(identifiers)
        
        if useCache && purchaseItems[uniqueIdentifier] != nil {
            completion(.success(purchaseItems[uniqueIdentifier] ?? []))
            return
        }
        
        // Use the store kit 1 only for now
        self.sk1Products(withIdentifiers: uniqueIdentifier) { skProducts in
            let result = skProducts
                .map { Set($0.map(SK1StoreProduct.init).map(KPSPurchaseItem.from(product:))) }
            
            completion(result)
            if let items = try? result.get() {
                self.purchaseItems[uniqueIdentifier] = items
            }
        }
    }
    
}

extension KPSPurchaseProductManager: SKProductsRequestDelegate {

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
       
        let identifiers = Set(response.products.map { $0.productIdentifier })
        
        guard let completionBlocks = self.completionHandlers[identifiers] else {
            
            for (key, value) in self.completionHandlers {
                if identifiers.isSubset(of: key) {
                    for completion in value {
                        completion(.success(Set(response.products)))
                    }
                }
                self.completionHandlers.removeValue(forKey: key)
            }
            return
        }

        self.completionHandlers.removeValue(forKey: identifiers)
        
        for completion in completionBlocks {
            completion(.success(Set(response.products)))
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        
        print("request finish")
        
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        
        print("request fail with error:\(error)")
        
    }

}
