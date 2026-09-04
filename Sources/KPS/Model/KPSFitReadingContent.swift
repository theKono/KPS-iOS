//
//  KPSFitReadingContent.swift
//  KPS-iOS
//
//  Created by Kono on 2022/8/11.
//

import Foundation

public enum KPSFitReadingBlockType: String {
    case paragraph
    case blockquote
    case heading
    case image
    case preface
    case separator = "horizontalRule"
    case unknow
}

public enum KPSFitReadingBlockAttr {
    case level(level: Int)
    case resourceId(id: String)
}

public struct KPSFitReadingContent: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case blocks = "content"
    }
    
    public let type: String
    public let blocks: [KPSFitReadingContentBlock]
}

public struct KPSFitReadingContentBlock: Decodable {
    enum CodingKeys: String, CodingKey {
        case type, attrs, htmlText
    }
    
    public let type: KPSFitReadingBlockType
    public let attrs: KPSFitReadingBlockAttr?
    public let htmlText: String?

    
}

extension KPSFitReadingContentBlock {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        
        let typeString = try baseContainer.decode(String.self, forKey: .type)
        type = KPSFitReadingBlockType(rawValue: typeString) ?? .unknow
        
        if let attrsDic = try baseContainer.decodeIfPresent([String: Any].self, forKey: .attrs) {
            switch type {
            case .heading:
                if let level = attrsDic["level"] as? Int {
                    attrs = .level(level: level)
                } else {
                    attrs = nil
                }
            case .image:
                if let id = attrsDic["resourceId"] as? String {
                    attrs = .resourceId(id: id)
                } else {
                    attrs = nil
                }
            default:
                attrs = nil
            }
        } else {
            attrs = nil
        }
        htmlText = try baseContainer.decodeIfPresent(String.self, forKey: .htmlText)
    }
    
}
