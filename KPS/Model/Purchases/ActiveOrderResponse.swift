//
//  ActiveOrderResponse.swift
//  KPS
//
//  Created by mingshing on 2022/4/12.
//

import Foundation
public struct ActiveOrderResponse {
    enum CodingKeys: String, CodingKey {
        case activeOrders
    }
    
    public var activeOrders: [KPSPurchaseOrder]
}

extension ActiveOrderResponse: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeOrders = try container.decode([KPSPurchaseOrder].self, forKey: .activeOrders)
    }
}
