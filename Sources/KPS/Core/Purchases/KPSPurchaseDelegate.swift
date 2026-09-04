//
//  PurchaseDelegate.swift
//  KPS
//
//  Created by mingshing on 2022/3/9.
//

import Foundation

public protocol KPSPurchasesDelegate: AnyObject {
    
    func kpsPurchase(purchase: KPSPurchases, customerTypeDidChange customerType: CustomerType)
        
}
