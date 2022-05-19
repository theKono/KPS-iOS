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

public enum CustomerPaymentStatus {
    static let interruptedByPause: String = "PAUSED"
    static let interruptedByKill: String = "KILLED"
    static let interruptedByPlanChanged: String = "UPDOWNGRADED"
    
    case Paused
    case Killed
    case Promotion
    case Paid
    case GracePeriod
    case OnHold
    case PlanChanged
    case None
    
    var subscriptionStatus: CustomerSubscriptionStatus {
        switch self {
        case .GracePeriod, .Paid, .PlanChanged:
            return .Active
        case .Promotion:
            return .Trial
        case .Paused, .OnHold, .Killed, .None:
            return .None
        }
    }
}


class SubscriptionManager {

    internal static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#
    private var serverUrl: String
    public var paymentStatus: CustomerPaymentStatus
    public var subscriptionStatus: CustomerSubscriptionStatus {
        return paymentStatus.subscriptionStatus
    }
    public var latestOrder: KPSPurchaseOrder?
    public var ownOrderIds: [String] = []
    public var syncDate: Date?
    init(serverUrl: String) {
        self.serverUrl = serverUrl
        self.paymentStatus = .None
    }

    static func generateRandomID() -> String {
        "$KPSAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }
    
    private func updateSubscriptionStatus() {
        if let order = latestOrder {
            let currentTimeStamp_ms = Date().timeIntervalSince1970 * 1000.0
            
            if let interruptedType = order.latestTransaction.interruptedType {
                if interruptedType == CustomerPaymentStatus.interruptedByKill {
                    paymentStatus = .Killed
                } else if interruptedType == CustomerPaymentStatus.interruptedByPause {
                    paymentStatus = .Paused
                } else if interruptedType == CustomerPaymentStatus.interruptedByPlanChanged {
                    paymentStatus = .PlanChanged
                }
            } else {
                if order.latestTransaction.end >= currentTimeStamp_ms {
                    paymentStatus = order.latestTransaction.isTrial ? .Promotion : .Paid
                } else {
                    if order.gracePeriodEnd != nil && order.gracePeriodEnd! > currentTimeStamp_ms {
                        paymentStatus = .GracePeriod
                    } else if order.nextPlan != nil {
                        paymentStatus = .OnHold
                    } else {
                        paymentStatus = .Killed
                    }
                }
            }
        } else {
            paymentStatus = .None
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
                    self?.ownOrderIds = orderResponse.activeOrders.map{ return $0.id}
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
        guard let latestOrder = latestOrder else {
            completion?(.success([]))
            return
        }

        PurchaseAPIServiceProvider.request(.fetchTransactions(order: latestOrder.id, serverUrl: self.serverUrl)) { result in
            
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let transactionResponse = try JSONDecoder().decode(TransactionResponse.self, from: filteredResponse.data)
                    
                    //DEBUG
                    //let response = String(decoding: response.data, as: UTF8.self)
                    //print(response)
                    completion?(.success(transactionResponse.transactions))
                    
                } catch {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    completion?(.success([]))
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion?(.failure(error))
                
            }
        }
        
    }
}
