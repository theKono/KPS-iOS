//
//  CustomerInfo.swift
//  KPS
//
//  Created by mingshing on 2022/3/14.
//

import Foundation



public class CustomerInfo: NSObject {
    
    public var subscriptionStatus: CustomerSubscriptionStatus
    public var syncDate: Date?
    
    override init() {
        subscriptionStatus = .Unknown
    }
    
    
}
