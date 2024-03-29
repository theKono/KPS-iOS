//
//  KPSContentMeta.swift
//  KPS
//
//  Created by mingshing on 2021/9/11.
//

public enum KPSContentType: String {
    case audio
    case article
    case folder
    case album
    case book
    case chapter
    case section
    case unknown
}

public struct KPSContentMeta {
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, description, covers, resources, content, info, customData, orderInParent, permissions
        case publicData = "public"
        case free
    }
    
    enum ContentDataKeys: String, CodingKey {
        case fitReading, pdf
    }
    
    public var id: String
    public var type: String?
    public var order: Int?
    public var isPublic, isFree: Bool?
    public var name, description: [String: String]?
    public var permissions: [String: Bool]?
    public var authors: [String:[String]]?
    public let publicContentInfo: [String: Any]?
    public var images: [KPSImageResource] = []
    public var customData: [String: Any]?
    public let pdfData: KPSPDFContent?
    public let fitReadingData: KPSFitReadingContent?
    public var isCollectionType: Bool {
        return type != "article" && type != "audio" && type != "video"
    }
    
    public var contentType: KPSContentType {
        let typeString: String = type ?? ""
        return KPSContentType(rawValue: typeString) ?? .unknown
    }
}

extension KPSContentMeta: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        order = try container.decodeIfPresent(Int.self, forKey: .orderInParent)
        name = try container.decodeIfPresent([String: String].self, forKey: .name)
        description = try container.decodeIfPresent([String: String].self, forKey: .description)
        publicContentInfo = try container.decodeIfPresent([String: Any].self, forKey: .content)
        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .content)
        pdfData = try contentDataContainer.decodeIfPresent(KPSPDFContent.self, forKey: .pdf)
        fitReadingData = try contentDataContainer.decodeIfPresent(KPSFitReadingContent.self, forKey: .fitReading)
        isPublic = try container.decodeIfPresent(Bool.self, forKey: .publicData)
        isFree = try container.decodeIfPresent(Bool.self, forKey: .free)
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)
        
        if !isCollectionType {
            permissions = try container.decodeIfPresent([String: Bool].self, forKey: .permissions)
        }
        
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
