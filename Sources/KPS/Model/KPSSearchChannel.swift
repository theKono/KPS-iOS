//
//  KPSSearchChannel.swift
//  KPS
//
//  Created by Kono on 2023/5/10.
//

import Foundation

public struct KPSSearchChannel: Decodable {
    enum CodingKeys: String, CodingKey {
        case error, result, tags
    }
    public var error: String?
    public var result: [KPSContentMeta]
    public var tags: [KPSTag]?
}

public struct KPSTag: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case pid, name,createTime, creatorId, translations
    }
    
    public var id: String
    public var pid: String?
    public var name: String?
    public var createTime: Int64?
    public var creatorId: String?
    public var translations: [String: String]?
    
}
