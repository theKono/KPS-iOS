//
//  KPSCouponManager.swift
//  KPS
//
//  Created by Kono on 2022/9/7.
//

import Foundation
import Moya

class KPSCouponManager {
    private var serverUrl: String
    private var apiServiceProvider: MoyaProvider<PurchaseAPIService>
    
    init(serverUrl: String, apiServiceProvider: MoyaProvider<PurchaseAPIService>) {
        self.serverUrl = serverUrl
        self.apiServiceProvider = apiServiceProvider
    }
    
    public func redeemCoupon(code: String, completion: @escaping(Result<KPSCouponResponse, MoyaError>) -> ()) {
        
        apiServiceProvider.request(.redeemKPSCoupon(couponId: code, serverUrl: self.serverUrl)) { result in
            
            switch result {
            case let .success(response):
                do {
                    let couponResponse = try JSONDecoder().decode(KPSCouponResponse.self, from: response.data)
                    
                    completion(.success(couponResponse))

                } catch {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    completion(.failure(MoyaError.jsonMapping(response)))
                    
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion(.failure(error))
            }
        }
    }
}
