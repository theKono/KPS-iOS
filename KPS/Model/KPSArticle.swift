//
//  KPSArticle.swift
//  KPS


public struct KPSArticle {
    
    enum CodingKeys: String, CodingKey {
        case article, error
    }
    
    enum RootKeys: String, CodingKey {
        case id,type,name,description
        case customData
        case res
    }
    
    enum ContentDataKeys: String, CodingKey {
        case image, fitReading, html
    }
    
    enum imageContainerKeys: String, CodingKey {
        case list
    }
    
    public let id, type, name, description: String
    
    public let customData, fitReadingData, pdfData: [String: Any]?
    
    public var images: [KPSImageResource]
    
}

extension KPSArticle: Decodable {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .article)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)

        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .res)
        
        fitReadingData = try contentDataContainer.decodeIfPresent([String: Any].self, forKey: .fitReading)
        pdfData = try contentDataContainer.decodeIfPresent([String: Any].self, forKey: .html)
        
        let listContainer = try contentDataContainer.nestedContainer(keyedBy: imageContainerKeys.self, forKey: .image)
        images = try listContainer.decode([KPSImageResource].self, forKey: .list)
        
    }
    
}

