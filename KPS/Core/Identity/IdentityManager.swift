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
    case TrialExpired
    case New
    case Unknown
    
}


class IdentityManager {

    internal static let anonymousRegex = #"\$RCAnonymousID:([a-z0-9]{32})$"#
    private var serverUrl: String
    public var subscriptionStatus: CustomerSubscriptionStatus {
        didSet {
            if oldValue != subscriptionStatus {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "KPSPurchaseStatusUpdated"), object: nil, userInfo: nil)
            } else {
                print(subscriptionStatus)
            }
        }
    }
    public var syncDate: Date?
    init(serverUrl: String) {
        self.serverUrl = serverUrl
        self.subscriptionStatus = .Unknown
        //updatePaymentStatus()
    }

    static func generateRandomID() -> String {
        "$KPSAnonymousID:\(UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased())"
    }
    
    public func updatePaymentStatus() {
        
        subscriptionStatus = .Active
        
        /*
        PurchaseAPIServiceProvider.request(.fetchPaymentStatus(serverUrl: self.serverUrl)) { [weak self] result in
            
            self?.syncDate = Date()
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let _ = String(decoding: filteredResponse.data, as: UTF8.self)
                    
                    
                } catch _ {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                
            }
        }
        */
    }
    
    public func fetchTransactions() {
        
        PurchaseAPIServiceProvider.request(.fetchTransactions(serverUrl: self.serverUrl)) { [weak self] result in
            
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let _ = String(decoding: filteredResponse.data, as: UTF8.self)
                    
                    
                } catch _ {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                
            }
        }
        
    }
}
