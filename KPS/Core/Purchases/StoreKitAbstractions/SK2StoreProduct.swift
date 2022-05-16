//
//  SK2StoreProduct.swift
//  KPS
//
//  Created by mingshing on 2022/3/11.
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import Foundation
import StoreKit

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
internal struct SK2StoreProduct: StoreProductType {

    init(sk2Product: SK2Product) {
        self._underlyingSK2Product = sk2Product
    }

    // We can't directly store instances of StoreKit.Product, since that causes
    // linking issues in iOS < 15, even with @available checks correctly in place.
    // So instead, we store the underlying product as Any and wrap it with casting.
    // https://openradar.appspot.com/radar?id=4970535809187840
    private let _underlyingSK2Product: Any
    var underlyingProduct: SK2Product {
        // swiftlint:disable:next force_cast
        _underlyingSK2Product as! SK2Product
    }

    var localizedDescription: String { underlyingProduct.description }

    var price: Decimal { underlyingProduct.price }

    var localizedCurrencyString: String { return "" }
    
    var localizedCurrencySymbol: String { return "" }
    
    var localizedPriceString: String { underlyingProduct.displayPrice }

    var productIdentifier: String { underlyingProduct.id }

    var isFamilyShareable: Bool { underlyingProduct.isFamilyShareable }

    var localizedTitle: String { underlyingProduct.displayName }

    var priceFormatter: NumberFormatter? {
        // note: if we ever need more information from the jsonRepresentation object, we
        // should use Codable or another decoding method to clean up this code.
        guard let attributes = jsonDict["attributes"] as? [String: Any],
              let offers = attributes["offers"] as? [[String: Any]],
              let currencyCode: String = offers.first?["currencyCode"] as? String else {
                  return nil
              }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = .autoupdatingCurrent
        return formatter
    }

    var subscriptionGroupIdentifier: String? {
        underlyingProduct.subscription?.subscriptionGroupID
    }

    private var jsonDict: [String: Any] {
        let decoded = try? JSONSerialization.jsonObject(with: self.underlyingProduct.jsonRepresentation, options: [])
        return decoded as? [String: Any] ?? [:]
    }

    var subscriptionPeriod: SubscriptionPeriod? {
        guard let skSubscriptionPeriod = underlyingProduct.subscription?.subscriptionPeriod else {
            return nil
        }
        return SubscriptionPeriod.from(sk2SubscriptionPeriod: skSubscriptionPeriod)
    }

    var introductoryDiscount: StoreProductDiscount? {
        self.underlyingProduct.subscription?.introductoryOffer
            .map(StoreProductDiscount.init)
    }

    var discounts: [StoreProductDiscount] {
        (self.underlyingProduct.subscription?.promotionalOffers ?? [])
            .compactMap(StoreProductDiscount.init)
    }

}

@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
extension SK2StoreProduct: Hashable {

    static func == (lhs: SK2StoreProduct, rhs: SK2StoreProduct) -> Bool {
        return lhs.underlyingProduct == rhs.underlyingProduct
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.underlyingProduct)
    }

}
