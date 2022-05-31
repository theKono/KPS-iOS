//
//  KPSArticle.swift
//  KPS


public struct KPSArticle {
    
    enum CodingKeys: String, CodingKey {
        case contentNode, error, puser, parentNode, siblingNodes
    }
    
    enum RootKeys: String, CodingKey {
        case id,type,name,description
        case orderInParent
        case customData
        case covers
        case info
        case resources
        case publicData = "public"
        case free
        case permissions
        case content
    }
    
    enum ContentDataKeys: String, CodingKey {
        case fitReading, pdf
    }
    
    enum coverContainerKeys: String, CodingKey {
        case list
    }
    
    enum infoContainerKeys: String, CodingKey {
        case authors
    }
    
    public let id, type: String
    public let name, description, authors: [String: String]
    public let order: Int
    public let coverList: [String]
    public let isPublic, isFree: Bool
    public var permissions: [String: Bool]?
    public let customData, fitReadingData, pdfData: [String: Any]?
    public var images: [KPSImageResource]
    
    public var parent: KPSContentMeta?
    public var siblings: [KPSContentMeta]?
    
    
}

extension KPSArticle: Decodable {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .contentNode)
        
        parent = try baseContainer.decodeIfPresent(KPSContentMeta.self, forKey: .parentNode)
        siblings = try baseContainer.decodeIfPresent([KPSContentMeta].self, forKey: .siblingNodes)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode([String: String].self, forKey: .name)
        description = try container.decode([String: String].self, forKey: .description)
        
        order = try container.decode(Int.self, forKey: .orderInParent)
        
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)
        
        let covers = try container.nestedContainer(keyedBy: coverContainerKeys.self, forKey: .covers)
        coverList = try covers.decode([String].self, forKey: .list)
                
        let info = try container.nestedContainer(keyedBy: infoContainerKeys.self, forKey: .info)
        authors = try info.decode([String: String].self, forKey: .authors)
        
        images = try container.decode([KPSImageResource].self, forKey: .resources)
        
        isPublic = try container.decode(Bool.self, forKey: .publicData)
        isFree = try container.decode(Bool.self, forKey: .free)

        permissions = try container.decodeIfPresent([String: Bool].self, forKey: .permissions)
                                       
        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .content)
        
        fitReadingData = try contentDataContainer.decodeIfPresent([String: Any].self, forKey: .fitReading)
        pdfData = try contentDataContainer.decodeIfPresent([String: Any].self, forKey: .pdf)
        
    }
    
}

