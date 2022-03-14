//
//  KPSPurchaseItem.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//

import Foundation
import StoreKit

/// TypeAlias to StoreKit 1's Product type, called `StoreKit/SKProduct`
public typealias SK1Product = SKProduct

/// TypeAlias to StoreKit 2's Product type, called `StoreKit.Product`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias SK2Product = StoreKit.Product


public final class KPSPurchaseItem: NSObject, StoreProductType {
    
    let product: StoreProductType

    /// Designated initializer.
    /// - Seealso: ``StoreProduct.from(product:)`` to wrap an instance of `StoreProduct`
    private init(_ product: StoreProductType) {
        self.product = product

        super.init()
    }

    /// Creates an instance from any `StoreProductType`.
    /// If `product` is already a wrapped `StoreProduct` then this returns it instead.
    static func from(product: StoreProductType) -> KPSPurchaseItem {
        return product as? KPSPurchaseItem
            ?? KPSPurchaseItem(product)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        return self.productIdentifier == (object as? StoreProductType)?.productIdentifier
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.productIdentifier)

        return hasher.finalize()
    }

    public var localizedDescription: String { self.product.localizedDescription }

    public var localizedTitle: String { self.product.localizedTitle }

    public var price: Decimal { self.product.price }
    
    public var localizedCurrencyString: String { self.product.localizedCurrencyString }
    
    public var localizedCurrencySymbol: String { self.product.localizedCurrencySymbol }

    public var localizedPriceString: String { self.product.localizedPriceString}

    public var productIdentifier: String { self.product.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    public var isFamilyShareable: Bool { self.product.isFamilyShareable }

    public var subscriptionGroupIdentifier: String? { self.product.subscriptionGroupIdentifier}

    public var priceFormatter: NumberFormatter? { self.product.priceFormatter }

    public var subscriptionPeriod: SubscriptionPeriod? { self.product.subscriptionPeriod }

    public var introductoryDiscount: StoreProductDiscount? { self.product.introductoryDiscount }

    public var discounts: [StoreProductDiscount] { self.product.discounts }

}

/// Type that provides access to all of `StoreKit`'s product type's properties.
internal protocol StoreProductType {

    /// A description of the product.
    /// - Note: The description's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    var localizedDescription: String { get }

    /// The name of the product.
    /// - Note: The title's language is determined by the storefront that the user's device is connected to,
    /// not the preferred language set on the device.
    var localizedTitle: String { get }

    /// The decimal representation of the cost of the product, in local currency.
    /// For a string representation of the price to display to customers, use ``localizedPriceString``.
    /// - Seealso: `pricePerMonth`.
    var price: Decimal { get }

    
    var localizedCurrencyString: String { get }
    
    var localizedCurrencySymbol: String { get }
    
    /// The price of this product using ``priceFormatter``.
    var localizedPriceString: String { get }

    /// The string that identifies the product to the Apple App Store.
    var productIdentifier: String { get }

    /// A Boolean value that indicates whether the product is available for family sharing in App Store Connect.
    /// Check the value of `isFamilyShareable` to learn whether an in-app purchase is sharable with the family group.
    ///
    /// When displaying in-app purchases in your app, indicate whether the product includes Family Sharing
    /// to help customers make a selection that best fits their needs.
    ///
    /// Configure your in-app purchases to allow Family Sharing in App Store Connect.
    /// For more information about setting up Family Sharing, see Turn-on Family Sharing for in-app purchases.
    /// - Seealso: https://support.apple.com/en-us/HT201079
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    var isFamilyShareable: Bool { get }

    /// The identifier of the subscription group to which the subscription belongs.
    /// All auto-renewable subscriptions must be a part of a group.
    /// You create the group identifiers in App Store Connect.
    /// This property is `nil` if the product is not an auto-renewable subscription.
    var subscriptionGroupIdentifier: String? { get }

    /// Provides a `NumberFormatter`, useful for formatting the price for displaying.
    /// - Note: This creates a new formatter for every product, which can be slow.
    /// - Returns: `nil` for StoreKit 2 backed products if the currency code could not be determined.
    var priceFormatter: NumberFormatter? { get }

    /// The period details for products that are subscriptions.
    /// - Returns: `nil` if the product is not a subscription.
    var subscriptionPeriod: SubscriptionPeriod? { get }

    /// The object containing introductory price information for the product.
    /// If you've set up introductory prices in App Store Connect, the introductory price property will be populated.
    /// This property is `nil` if the product has no introductory price.
    ///
    /// Before displaying UI that offers the introductory price,
    /// you must first determine if the user is eligible to receive it.
    /// - Seealso: `Purchases.checkTrialOrIntroductoryPriceEligibility` to  determine eligibility.
    var introductoryDiscount: StoreProductDiscount? { get }

    /// An array of subscription offers available for the auto-renewable subscription.
    var discounts: [StoreProductDiscount] { get }
}

public extension KPSPurchaseItem {

    /// Calculates the price of this subscription product per month.
    /// - Returns: `nil` if the product is not a subscription.
    var pricePerMonth: NSDecimalNumber? {
        guard let period = self.subscriptionPeriod,
              period.unit != .unknown else {
                  return nil
              }

        return period.pricePerMonth(withTotalPrice: self.price) as NSDecimalNumber?
    }

    /// The price of the `introductoryPrice` formatted using ``priceFormatter``.
    /// - Returns: `nil` if there is no `introductoryPrice`.
    var localizedIntroductoryPriceString: String? {

        guard let formatter = self.priceFormatter,
              let intro = self.introductoryDiscount
        else {
            return nil
        }
        return formatter.string(from: intro.price as NSDecimalNumber)
    }

}

// MARK: - Wrapper constructors / getters

extension KPSPurchaseItem {

    internal convenience init(sk1Product: SK1Product) {
        self.init(SK1StoreProduct(sk1Product: sk1Product))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init(sk2Product: SK2Product) {
        self.init(SK2StoreProduct(sk2Product: sk2Product))
    }

    /// Returns the `SKProduct` if this `StoreProduct` represents a `StoreKit.SKProduct`.
    public var sk1Product: SK1Product? {
        return (self.product as? SK1StoreProduct)?.underlyingProduct
    }

    /// Returns the `Product` if this `StoreProduct` represents a `StoreKit.Product`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public var sk2Product: SK2Product? {
        return (self.product as? SK2StoreProduct)?.underlyingProduct
    }

}
