//
//  SK1StoreProductDiscount.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
import StoreKit

internal struct SK1StoreProductDiscount: StoreProductDiscountType {

    init(sk1Discount: SK1ProductDiscount) {
        self.underlyingDiscount = sk1Discount

        self.offerIdentifier = sk1Discount.identifier
        self.price = sk1Discount.price as Decimal
        self.paymentMode = .init(skProductDiscountPaymentMode: sk1Discount.paymentMode)
        self.subscriptionPeriod = .from(sk1SubscriptionPeriod: sk1Discount.subscriptionPeriod)
    }

    let underlyingDiscount: SK1ProductDiscount

    let offerIdentifier: String?
    let price: Decimal
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod

}

extension StoreProductDiscount.PaymentMode {

    @available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
    init(skProductDiscountPaymentMode paymentMode: SKProductDiscount.PaymentMode) {
        switch paymentMode {
        case .payUpFront:
            self = .payUpFront
        case .payAsYouGo:
            self = .payAsYouGo
        case .freeTrial:
            self = .freeTrial
        @unknown default:
            self = .none
        }
    }

}
