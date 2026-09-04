//
//  ProductIdsResponse.swift
//  KPS
//
//  Created by mingshing on 2022/4/28.
//

import Foundation
public struct ProductIdsResponse {
    enum CodingKeys: String, CodingKey {
        case error, productIds
    }
    
    public var error: String?
    public var productIds: [String]?
}

extension ProductIdsResponse: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        error = try container.decodeIfPresent(String.self, forKey: .error)
        productIds = try container.decodeIfPresent([String].self, forKey: .productIds)
    }
}
