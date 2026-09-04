//
//  PurchaseAPIService.swift
//  KPS
//
//  Created by mingshing on 2022/3/15.
//

import Moya

let PurchaseAPIServiceProvider = MoyaProvider<PurchaseAPIService>()
//let PurchaseAPIServiceProvider = MoyaProvider<PurchaseAPIService>(stubClosure: MoyaProvider.delayedStub(0.2))
//let PurchaseAPIServiceProvider = MoyaProvider<PurchaseAPIService>(stubClosure: MoyaProvider.immediatelyStub)
                                                                                   
enum PurchaseAPIService {
    
    case uploadReceipt(receipt: String, version: Int, serverUrl: String)
    case fetchPaymentStatus(serverUrl: String)
    case fetchTransactions(order: String, serverUrl: String)
    case fetchProductIds(serverUrl: String)
    case redeemKPSCoupon(couponId: String, serverUrl: String)

}

extension PurchaseAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .uploadReceipt(_, _, let serverUrl), .fetchPaymentStatus(let serverUrl), .fetchTransactions(_, let serverUrl), .fetchProductIds(let serverUrl), .redeemKPSCoupon(_, let serverUrl):
            return URL(string: serverUrl)!
        }
    }
    
    var path: String {
        switch self {
        case .uploadReceipt(_, _, _):
            return "appleOrders"
        case .fetchPaymentStatus(_):
            return "activeOrders"
        case .fetchTransactions(_, _):
            return "transactions"
        case .fetchProductIds(_):
            return "productIds"
        case .redeemKPSCoupon(let couponId, _):
            return "coupons/\(couponId)/redeem"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .uploadReceipt(_, _, _), .redeemKPSCoupon(_, _):
            return .post
        case .fetchPaymentStatus(_), .fetchTransactions(_, _), .fetchProductIds(_):
            return .get
        }
    }
    
    var sampleData: Data {
        switch self {
        case .uploadReceipt(_, _, _):
            return Data()
        case .fetchPaymentStatus(_):
            guard let url = Bundle.resourceBundle.url(forResource: "activeOrders", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchTransactions(_, _):
            guard let url = Bundle.resourceBundle.url(forResource: "transactions", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        case .fetchProductIds(_):
            guard let url = Bundle.resourceBundle.url(forResource: "productIds", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
            
        case .redeemKPSCoupon(let couponId, _):
            var resFileName: String
            if couponId == "couponRedeemWithError" {
                resFileName = "couponRedeemWithError"
            } else {
                resFileName = "couponRedeem"
            }
            
            guard let url = Bundle.resourceBundle.url(forResource: resFileName, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                        return Data()
                    }
            return data
        }
    }
    
    var task: Task {
        switch self {
        case .uploadReceipt(let receipt, let version, _):
            return .requestParameters(parameters: ["receipt": receipt, "storeKitVersion": version], encoding: JSONEncoding.default)
        case .fetchPaymentStatus(_), .fetchProductIds(_), .redeemKPSCoupon(_, _):
            return .requestPlain
        case .fetchTransactions(let order, _):
            return .requestParameters(parameters: ["orderId": order], encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
