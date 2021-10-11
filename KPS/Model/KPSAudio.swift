//
//  KPSAudio.swift
//  KPS
//
//  Created by mingshing on 2021/8/18.
//

import Foundation

public struct KPSAudioContent {
    
    enum CodingKeys: String, CodingKey {
        case error, contentNode
    }
    
    enum RootKeys: String, CodingKey {
        case id, type, name, description, orderInParent
        case customData
        case publicData = "public"
        case free
        case covers
        case resources, content
    }
    
    enum ContentDataKeys: String, CodingKey {
        case textSegments, languages, audioLanguage, length, resource
    }
    
    enum imageContainerKeys: String, CodingKey {
        case list
    }
    
    public let id, type: String
    public let name, description: [String: String]
    public let order: Int
    public let length: Double
    public let isPublic, isFree: Bool
    public let customData: [String: Any]?
    public let content: [KPSAudioText]
    public var streamingUrl: URL
    public var collectionId: String?
    public var collectionName: [String: String]?
    
}

extension KPSAudioContent: Decodable {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .contentNode)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode([String: String].self, forKey: .name)
        description = try container.decode([String: String].self, forKey: .description)
        order = try container.decode(Int.self, forKey: .orderInParent)
        isPublic = try container.decode(Bool.self, forKey: .publicData)
        isFree = try container.decode(Bool.self, forKey: .free)
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)

        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .content)
        let defaultLang = try contentDataContainer.decode(String.self, forKey: .audioLanguage)
        let audioResourceId = try contentDataContainer.decode(String.self, forKey: .resource)
        let textTypeInfos: [[String: Any]] = try contentDataContainer.decode([[String : Any]].self, forKey: .textSegments)
        let textLangInfos: [String: Any] = try contentDataContainer.decode([String : Any].self, forKey: .languages)
        var parsedText = [KPSAudioText]()
        
        for i in 0..<textTypeInfos.count {
            let audioText = KPSAudioText(typeInfo: textTypeInfos[i], lang: defaultLang)
            parsedText.append(audioText)
        }
        
        for lang in textLangInfos.keys {
            let translation = textLangInfos[lang] as! [[String: String]]
            for i in 0..<parsedText.count {
                parsedText[i].translation[lang] = translation[i]["content"]
            }
            
        }
        content = parsedText
        
        let resources = try container.decode([String: Any].self, forKey: .resources)
        let audioResourceInfo = resources[audioResourceId] as! [String: Any]
        length = audioResourceInfo["duration"] as! Double
        streamingUrl = URL(string: audioResourceInfo["streamingUrl"] as! String)!
    }
    
    public init (url: URL) {
        
        streamingUrl = url
        id = ""
        type = "Invalid"
        name = [String: String]()
        description = [String: String]()
        length = 0.0
        order = -1
        isPublic = false
        isFree = false
        customData = [String: Any]()
        content = [KPSAudioText]()
    }
    
}

public struct KPSAudioText {
    
    public let type: String
    public let defaultLang: String
    public let startTime, endTime: Double
    public var translation: [String: String]
    
    init(typeInfo: [String: Any], lang: String) {
        
        type = typeInfo["type"] as! String
        
        startTime = Double(typeInfo["start"] as! Int)
        endTime = Double(typeInfo["end"] as! Int)
        defaultLang = lang
        translation = [String: String]()
    }
    
    public var text: String {
        if let content = translation[defaultLang] {
            return content
        } else {
            return ""
        }
    }
}

