//
//  KPSPurchaseDelegateMock.swift
//  KPSTests
//
//  Created by mingshing on 2022/4/18.
//

import Foundation
@testable import KPS

class KPSPurchaseDelegateMock: KPSPurchasesDelegate {

    private(set) var customerType: CustomerType?
        
    func kpsPurchase(purchase: KPSPurchases, customerTypeDidChange customerType: CustomerType) {
        self.customerType = customerType
    }
}
