//
//  SK2StoreProductDiscount.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//  Copyright RevenueCat Inc. All Rights Reserved.vv
//

import Foundation
import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2StoreProductDiscount: StoreProductDiscountType {

    init(sk2Discount: SK2ProductDiscount) {
        self.underlyingDiscount = sk2Discount

        self.offerIdentifier = sk2Discount.id
        self.price = sk2Discount.price
        self.paymentMode = .init(subscriptionOfferPaymentMode: sk2Discount.paymentMode)
        self.subscriptionPeriod = .from(sk2SubscriptionPeriod: sk2Discount.period)
    }

    let underlyingDiscount: SK2ProductDiscount

    let offerIdentifier: String?
    let price: Decimal
    let paymentMode: StoreProductDiscount.PaymentMode
    let subscriptionPeriod: SubscriptionPeriod

}

private extension StoreProductDiscount.PaymentMode {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    init(subscriptionOfferPaymentMode paymentMode: Product.SubscriptionOffer.PaymentMode) {
        switch paymentMode {
        case .payUpFront:
            self = .payUpFront
        case .payAsYouGo:
            self = .payAsYouGo
        case .freeTrial:
            self = .freeTrial
        default:
            self = .none
        }
    }
}
