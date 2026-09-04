//
//  TransactionResponse.swift
//  KPS
//
//  Created by mingshing on 2022/4/12.
//

import Foundation

public struct TransactionResponse {
    enum CodingKeys: String, CodingKey {
        case transactions
    }
    
    public var transactions: [KPSPurchaseTransaction]
}

extension TransactionResponse: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        transactions = try container.decode([KPSPurchaseTransaction].self, forKey: .transactions)
    }
}
