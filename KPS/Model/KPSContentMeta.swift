//
//  KPSContentMeta.swift
//  KPS
//
//  Created by mingshing on 2021/9/11.
//

public struct KPSContentMeta {
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, description, covers,resources,content,info
        case publicData = "public"
        case free
    }
    
    public var id, type: String
    public var isPublic, isFree: Bool?
    public var name, description: [String: String]
    public var authors: [String:[String]]?
    public let publicContentInfo: [String: Any]?
    public var images: [KPSImageResource]
    
    public var isCollectionType: Bool {
        return type != "article" && type != "audio" && type != "video"
    }
}

extension KPSContentMeta: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode([String: String].self, forKey: .name)
        description = try container.decode([String: String].self, forKey: .description)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .publicData)
        isFree = try container.decodeIfPresent(Bool.self, forKey: .free)
        publicContentInfo = try container.decode([String: Any].self, forKey: .content)
        
        if let contentInfo = try container.decodeIfPresent([String: Any].self, forKey: .info) {
            if contentInfo["authors"] != nil {
                authors = contentInfo["authors"] as? [String: [String]]
            }
        }
        
        let coverIdContainer = try container.decode([String:[String]].self, forKey: .covers)
        let coverResourceIds = coverIdContainer["list"]!
        
        let resourceContainter = try container.decode([String: KPSImageResource].self, forKey: .resources)
        
        images = []
        for id in coverResourceIds {
            if let image = resourceContainter[id] {
                images.append(image)
            }
        }
        
    }

}
