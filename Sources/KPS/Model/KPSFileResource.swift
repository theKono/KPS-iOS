//
//  KPSResource.swift
//  KPS
//
//  Created by Kono on 2022/6/7.
//

public struct KPSFileResource: Decodable {
    public let type: String
    public let url: String
    public let mimeType: String

    enum CodingKeys: String, CodingKey {
        case url, mimeType, type
    }
}
