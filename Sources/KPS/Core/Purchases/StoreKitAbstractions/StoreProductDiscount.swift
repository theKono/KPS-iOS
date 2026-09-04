//
//  StoreProductDiscount.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
import StoreKit

/// TypeAlias to StoreKit 1's Discount type, called `SKProductDiscount`
public typealias SK1ProductDiscount = SKProductDiscount

/// TypeAlias to StoreKit 2's Discount type, called `StoreKit.Product.SubscriptionOffer`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias SK2ProductDiscount = StoreKit.Product.SubscriptionOffer

public final class StoreProductDiscount: NSObject, StoreProductDiscountType {

    public enum PaymentMode: Int {
        case none = -1
        case payAsYouGo = 0
        case payUpFront = 1
        case freeTrial = 2
    }

    private let discount: StoreProductDiscountType

    init(_ discount: StoreProductDiscountType) {
        self.discount = discount

        super.init()
    }

    public var offerIdentifier: String? { self.discount.offerIdentifier }
    public var price: Decimal { self.discount.price }
    public var paymentMode: PaymentMode { self.discount.paymentMode }
    public var subscriptionPeriod: SubscriptionPeriod { self.discount.subscriptionPeriod }

    /// Creates an instance from any `StoreProductDiscountType`.
    /// If `discount` is already a wrapped `StoreProductDiscount` then this returns it instead.
    static func from(discount: StoreProductDiscountType) -> StoreProductDiscount {
        return discount as? StoreProductDiscount
        ?? StoreProductDiscount(discount)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? StoreProductDiscount else { return false }

        return self.offerIdentifier == other.offerIdentifier
            && self.price == other.price
            && self.paymentMode == other.paymentMode
            && self.subscriptionPeriod == other.subscriptionPeriod
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.offerIdentifier)
        hasher.combine(self.price)
        hasher.combine(self.paymentMode)
        hasher.combine(self.subscriptionPeriod)

        return hasher.finalize()
    }

}

/// The details of an introductory offer or a promotional offer for an auto-renewable subscription.
internal protocol StoreProductDiscountType {

    /// A string used to uniquely identify a discount offer for a product.
    var offerIdentifier: String? { get }

    /// The discount price of the product in the local currency.
    var price: Decimal { get }

    /// The payment mode for this product discount.
    var paymentMode: StoreProductDiscount.PaymentMode { get }

    /// The period for the product discount.
    var subscriptionPeriod: SubscriptionPeriod { get }

}

// MARK: - Wrapper constructors / getters

extension StoreProductDiscount {

    internal convenience init(sk1Discount: SK1ProductDiscount) {
        self.init(SK1StoreProductDiscount(sk1Discount: sk1Discount))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init(sk2Discount: SK2ProductDiscount) {
        self.init(SK2StoreProductDiscount(sk2Discount: sk2Discount))
    }

    /// Returns the `SK1ProductDiscount` if this `StoreProductDiscount` represents a `SKProductDiscount`.
    @available(iOS 12.2, macOS 10.14.4, tvOS 12.2, watchOS 6.2, *)
    public var sk1Discount: SK1ProductDiscount? {
        return (self.discount as? SK1StoreProductDiscount)?.underlyingDiscount
    }

    /// Returns the `SK2ProductDiscount` if this `StoreProductDiscount` represents a `Product.SubscriptionOffer`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public var sk2Discount: SK2ProductDiscount? {
        return (self.discount as? SK2StoreProductDiscount)?.underlyingDiscount
    }

}

// MARK: - Encodable

extension StoreProductDiscount: Encodable {

    private enum CodingKeys: String, CodingKey {

        case offerIdentifier = "offer_identifier"
        case price = "price"
        case paymentMode = "payment_mode"

    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.offerIdentifier, forKey: .offerIdentifier)
        // Note: price is encoded price as `String` (using `NSDecimalNumber.description`)
        // to preserve precision and avoid values like "1.89999999"
        try container.encode((self.price as NSDecimalNumber).description, forKey: .price)
        try container.encode(self.paymentMode, forKey: .paymentMode)
    }

}

extension StoreProductDiscount.PaymentMode: Encodable { }
