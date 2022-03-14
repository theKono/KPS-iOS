//
//  CustomerInfo.swift
//  KPS
//
//  Created by mingshing on 2022/3/14.
//

import Foundation

public enum CustomerSubscriptionStatus {
    
    case Active
    case Trial
    case TrialExpired
    case New
    case Unknown
    
}


public class CustomerInfo: NSObject {
    
    public var subscriptionStatus: CustomerSubscriptionStatus
    public var syncDate: Date?
    
    override init() {
        subscriptionStatus = .Unknown
    }
    
    
}
