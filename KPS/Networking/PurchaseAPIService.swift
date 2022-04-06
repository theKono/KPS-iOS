//
//  PurchaseAPIService.swift
//  KPS
//
//  Created by mingshing on 2022/3/15.
//

import Moya

let PurchaseAPIServiceProvider = MoyaProvider<PurchaseAPIService>()
                                                                                   
enum PurchaseAPIService {
    
    case uploadReceipt(receipt: String, version: Int, serverUrl: String)
    case fetchPaymentStatus(serverUrl: String)
    case fetchTransactions(serverUrl: String)

}

extension PurchaseAPIService: TargetType {
    
    var baseURL: URL {
        switch self {
        case .uploadReceipt(_, _, let serverUrl), .fetchPaymentStatus(let serverUrl), .fetchTransactions(let serverUrl):
            return URL(string: serverUrl)!
        }
    }
    
    var path: String {
        switch self {
        case .uploadReceipt(_, _, _):
            return "appleOrders"
        case .fetchPaymentStatus(_):
            return "paymentStatus"
        case .fetchTransactions(_):
            return "transactions"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .uploadReceipt(_, _, _):
            return .post
        case .fetchPaymentStatus(_), .fetchTransactions(_):
            return .get
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .uploadReceipt(let receipt, let version, _):
            return .requestParameters(parameters: ["receipt": receipt, "storeKitVersion": version], encoding: JSONEncoding.default)
        case .fetchPaymentStatus(_), .fetchTransactions(_):
            return .requestPlain
        }
    }
    
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
