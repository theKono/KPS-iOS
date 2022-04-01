//
//  KPSContentMeta.swift
//  KPS
//
//  Created by mingshing on 2021/9/11.
//

public struct KPSContentMeta {
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, description, covers, resources, content, info, customData, orderInParent
        case publicData = "public"
        case free
    }
    
    public var id: String
    public var type: String?
    public var order: Int?
    public var isPublic, isFree: Bool?
    public var name, description: [String: String]?
    public var authors: [String:[String]]?
    public let publicContentInfo: [String: Any]?
    public var images: [KPSImageResource] = []
    public var customData: [String: Any]?
    public var isCollectionType: Bool {
        return type != "article" && type != "audio" && type != "video"
    }
}

extension KPSContentMeta: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        order = try container.decodeIfPresent(Int.self, forKey: .orderInParent)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decodeIfPresent([String: String].self, forKey: .name)
        description = try container.decodeIfPresent([String: String].self, forKey: .description)
        publicContentInfo = try container.decodeIfPresent([String: Any].self, forKey: .content)
        
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .publicData)
        isFree = try container.decodeIfPresent(Bool.self, forKey: .free)
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)
        
        if let contentInfo = try container.decodeIfPresent([String: Any].self, forKey: .info) {
            if contentInfo["authors"] != nil {
                authors = contentInfo["authors"] as? [String: [String]]
            }
        }
        
        if let coverIdContainer = try container.decodeIfPresent([String:[String]].self, forKey: .covers) {
            let coverResourceIds = coverIdContainer["list"]!
            
            let resourceContainter = try container.decode([String: KPSImageResource].self, forKey: .resources)
            for id in coverResourceIds {
                if let image = resourceContainter[id] {
                    images.append(image)
                }
            }
        }
        
    }

}
