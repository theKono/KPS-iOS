//
//  KPSContent.swift
//  KPS


public struct KPSContent {
    
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
    
    public var images: [KPSImage]
    
}

extension KPSContent: Decodable {
    
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: RootKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)

        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .res)
        
        fitReadingData = try contentDataContainer.decodeIfPresent([String: Any].self, forKey: .fitReading)
        pdfData = try contentDataContainer.decodeIfPresent([String: Any].self, forKey: .html)
        
        let listContainer = try contentDataContainer.nestedContainer(keyedBy: imageContainerKeys.self, forKey: .image)
        images = try listContainer.decode([KPSImage].self, forKey: .list)
        
    }
    
}




