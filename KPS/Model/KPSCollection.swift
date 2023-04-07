//
//  KPSCollection.swift
//  KPS
//
//  Created by mingshing on 2021/9/11.
//

public struct KPSCollection {
    
    enum CodingKeys: String, CodingKey {
        case error, childNodes, contentNode, parentNode, siblingNodes, puser
    }
    enum RootKeys: String, CodingKey {
        case id, type, name, description, covers, resources
    }
    
    public var children: [KPSContentMeta]
    public var parent: KPSContentMeta?
    public var siblings: [KPSContentMeta]?
    public var id: String
    public var type: String?
    public var name, description: [String: String]?
    public var images: [KPSImageResource]
    public var metaData: KPSContentMeta
}

extension KPSCollection: Decodable {
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        children = try baseContainer.decode([KPSContentMeta].self, forKey: .childNodes)
        parent = try baseContainer.decodeIfPresent(KPSContentMeta.self, forKey: .parentNode)
        siblings = try baseContainer.decodeIfPresent([KPSContentMeta].self, forKey: .siblingNodes)
        
        metaData = try baseContainer.decode(KPSContentMeta.self, forKey: .contentNode)
        
        let user = try baseContainer.decodeIfPresent(KPSUserModel.self, forKey: .puser)
        if let user = user {
            KPSClient.shared.isUserBlocked = user.status == 0
        }
        
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .contentNode)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decodeIfPresent([String: String].self, forKey: .name)
        description = try container.decodeIfPresent([String: String].self, forKey: .description)
        images = []
        
        if let _ = type {
            let coverIdContainer = try container.decode([String:[String]].self, forKey: .covers)
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
