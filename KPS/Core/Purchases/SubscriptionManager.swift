//
//  IdentityManager.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//

import Foundation

public enum CustomerSubscriptionStatus {
    
    case Active
    case Trial
    case None
}


class SubscriptionManager {

    internal static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#
    private var serverUrl: String
    public var subscriptionStatus: CustomerSubscriptionStatus
    public var latestOrder: KPSPurchaseOrder?
    public var syncDate: Date?
    init(serverUrl: String) {
        self.serverUrl = serverUrl
        self.subscriptionStatus = .None
    }

    static func generateRandomID() -> String {
        "$KPSAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }
    
    private func updateSubscriptionStatus() {
        if let order = latestOrder {
            subscriptionStatus = order.latestTransaction.isTrial ? .Trial : .Active
        } else {
            subscriptionStatus = .None
        }
    }
    
    public func updatePaymentStatus(_ completion: (() -> Void)? = nil) {
        
        PurchaseAPIServiceProvider.request(.fetchPaymentStatus(serverUrl: self.serverUrl)) { [weak self] result in
            
            self?.syncDate = Date()
            defer {
                completion?()
            }
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let orderResponse = try JSONDecoder().decode(ActiveOrderResponse.self, from: filteredResponse.data)

                    self?.latestOrder = orderResponse.activeOrders.sorted {
                        $0.createTime > $1.createTime
                    }.first
                    
                    self?.updateSubscriptionStatus()
                } catch _ {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                
            }
        }
        
    }
    
    public func fetchTransactions(_ completion: ((Result<[KPSPurchaseTransaction], Error>) -> Void)?) {
        
        PurchaseAPIServiceProvider.request(.fetchTransactions(serverUrl: self.serverUrl)) { result in
            
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let transactionResponse = try JSONDecoder().decode(TransactionResponse.self, from: filteredResponse.data)
                    completion?(.success(transactionResponse.transactions))
                    
                } catch _ {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion?(.failure(error))
                
            }
        }
        
    }
}
