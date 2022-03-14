//
//  SK1StoreProduct.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import StoreKit

internal struct SK1StoreProduct: StoreProductType {

    init(sk1Product: SK1Product) {
        self.underlyingProduct = sk1Product
    }

    let underlyingProduct: SK1Product

    var localizedDescription: String { return underlyingProduct.localizedDescription }

    var price: Decimal { return underlyingProduct.price as Decimal }

    var localizedCurrencyString: String {
        
        let local = underlyingProduct.priceLocale
        let countryCode: String = local.regionCode ?? ""
        
        if (countryCode.range(of: "TW") != nil) {
            return "NT"
        }
        return underlyingProduct.priceLocale.currencyCode ?? ""
    }
    
    var localizedCurrencySymbol: String { return underlyingProduct.priceLocale.currencySymbol ?? "$" }
    
    var localizedPriceString: String {
        return priceFormatter?.string(from: underlyingProduct.price) ?? ""
    }

    var productIdentifier: String { return underlyingProduct.productIdentifier }

    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 8.0, *)
    var isFamilyShareable: Bool { underlyingProduct.isFamilyShareable }

    var localizedTitle: String { underlyingProduct.localizedTitle }

    var subscriptionGroupIdentifier: String? { underlyingProduct.subscriptionGroupIdentifier }

    var priceFormatter: NumberFormatter? {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        formatter.locale = underlyingProduct.priceLocale
        return formatter
    }

    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingProduct.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk1SubscriptionPeriod: skSubscriptionPeriod)
    }

    var introductoryDiscount: StoreProductDiscount? {
        return self.underlyingProduct.introductoryPrice
            .map(StoreProductDiscount.init)
    }

    var discounts: [StoreProductDiscount] {
        return self.underlyingProduct.discounts
            .map(StoreProductDiscount.init)
    }

}

extension SK1StoreProduct: Hashable {

    static func == (lhs: SK1StoreProduct, rhs: SK1StoreProduct) -> Bool {
        return lhs.underlyingProduct == rhs.underlyingProduct
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.underlyingProduct)
    }

}

