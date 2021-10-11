//
//  KPSCollection.swift
//  KPS
//
//  Created by mingshing on 2021/9/11.
//

public struct KPSCollection {
    
    enum CodingKeys: String, CodingKey {
        case error, childNodes, contentNode, parentNode, siblingNodes
    }
    enum RootKeys: String, CodingKey {
        case id,type,name,covers,resources
    }
    
    public var children: [KPSContentMeta]
    public var parent: KPSContentMeta?
    public var siblings: [KPSContentMeta]?
    public var id, type: String?
    public var name: [String: String]?
    public var images: [KPSImageResource]
}

extension KPSCollection: Decodable {
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        children = try baseContainer.decode([KPSContentMeta].self, forKey: .childNodes)
        
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .contentNode)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        name = try container.decodeIfPresent([String: String].self, forKey: .name)
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
