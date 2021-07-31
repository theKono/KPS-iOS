//
//  KPSContent.swift
//  KPS


public struct KPSContent {
    
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
    
    public var images: [KPSImage]
    
}

extension KPSContent: Decodable {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .article)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        customData = try container.decode([String: Any].self, forKey: .customData)

        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .res)
        
        fitReadingData = try contentDataContainer.decode([String: Any].self, forKey: .fitReading)
        pdfData = try contentDataContainer.decode([String: Any].self, forKey: .html)
        
        let listContainer = try contentDataContainer.nestedContainer(keyedBy: imageContainerKeys.self, forKey: .image)
        images = try listContainer.decode([KPSImage].self, forKey: .list)
        
    }
    
}


public struct KPSImage {
    
    public let id, uri: String
    public let width, height: Int
    public let thumbnailSizes: [Int]

    public var mainImageURL: String {
        return (baseURL ?? "") + uri
    }
    
    var baseURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, thumbnails, uri
    }

}

extension KPSImage: Decodable {

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        thumbnailSizes = try container.decode([Int].self, forKey: .thumbnails)
        uri = try container.decode(String.self, forKey: .uri)

    }
}

