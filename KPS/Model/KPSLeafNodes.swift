//
//  KPSLeafNodes.swift
//  KPS
//
//  Created by Kono on 2024/3/13.
//

import Foundation

public struct KPSLeafNodes: Decodable {
    public let error: String?
    public let leafNodes: [KPSContentMeta]

    enum CodingKeys: String, CodingKey {
        case error, leafNodes
    }

}
