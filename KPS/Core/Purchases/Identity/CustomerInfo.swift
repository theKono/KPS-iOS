//
//  CustomerInfo.swift
//  KPS
//
//  Created by mingshing on 2022/3/14.
//

import Foundation

public enum CustomerType: Equatable {
    
    public static func == (lhs: CustomerType, rhs: CustomerType) -> Bool {
        switch (lhs, rhs){
        case (.New, .New), (.Free, .Free), (.Trial_VIP, .Trial_VIP), (.VIP, .VIP), (.Unknown, .Unknown):
            return true
        default:
            return false
        }
    }
    
    case New
    case Free
    case Trial_VIP(currentPlan: String, nextPlan: String?, expireTime: TimeInterval)
    case VIP(currentPlan: String, nextPlan: String?, expireTime: TimeInterval)
    case Unknown
    
    
}
