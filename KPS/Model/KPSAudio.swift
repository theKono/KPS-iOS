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
    public let isPublic, isFree: Bool
    public var length: Double?
    public var customData: [String: Any]?
    public var content: [KPSAudioText] = []
    public var paragraphContents: [KPSAudioText] = []
    internal var timeFrames: [TimeFrameInfo] = []
    public var streamingUrl: URL?
    public var collectionId: String?
    public var collectionName: [String: String]?
    public var collectionImage: KPSImageResource?
    public var errorDescription: String?
    public var error: KPSContentError?
    
}

extension KPSAudioContent: Decodable {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        let errorDescription = try baseContainer.decodeIfPresent(String.self, forKey: .error)
        
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
        
        //premium content
        if errorDescription == nil {
            let audioResourceId = try contentDataContainer.decode(String.self, forKey: .resource)
            let textTypeInfos: [KPSAudioTextInfo] = try contentDataContainer.decode([KPSAudioTextInfo].self, forKey: .textSegments)
            let textLangInfos: [String: Any] = try contentDataContainer.decode([String : Any].self, forKey: .languages)
            var parsedText = [KPSAudioText]()
        
            var encounterParagraphEnd: Bool = true
            for i in 0..<textTypeInfos.count {
                let audioText = KPSAudioText(info: textTypeInfos[i], idx: i, lang: defaultLang)
                parsedText.append(audioText)
                if audioText.startTime != audioText.endTime {
                    timeFrames.append(TimeFrameInfo(audioText, idx: i))
                }
                
                if audioText.type == "SPACE" {
                    encounterParagraphEnd = true
                } else if !paragraphContents.isEmpty && !encounterParagraphEnd {
                    let lastIdx = paragraphContents.count - 1
                    paragraphContents[lastIdx].segmentIdx = i
                    paragraphContents[lastIdx].endTime = textTypeInfos[i].end.doubleValue
                } else if encounterParagraphEnd {
                    encounterParagraphEnd = false
                    let paragraphText = KPSAudioText(info: textTypeInfos[i], idx: i, lang: defaultLang)
                    paragraphContents.append(paragraphText)
                }
                
            }
            timeFrames.sort { (frame1, frame2) in
                return frame1.startTime < frame2.startTime
            }
            for lang in textLangInfos.keys {
                let translation = textLangInfos[lang] as! [[String: String]]
                for i in 0..<parsedText.count {
                    parsedText[i].translation[lang] = translation[i]["content"]
                }
                var translationIdx: Int = 0
                for itemIdx in 0..<paragraphContents.count {
                    var currentLocation = 0
                    var currentLength = 0
                    
                    for i in translationIdx...paragraphContents[itemIdx].segmentIdx {
                        
                        if let sentence = translation[i]["content"] {
                            if paragraphContents[itemIdx].translation[lang] == nil {
                                paragraphContents[itemIdx].translation[lang] = sentence
                                
                                currentLength = sentence.withoutHtmlTags.count
                            } else {
                                var nextSentence = paragraphContents[itemIdx].translation[lang]!.isEmpty ? "" : " "
                                nextSentence += (translation[i]["content"] ?? "")
                                paragraphContents[itemIdx].translation[lang]! += nextSentence
                                
                                currentLength = nextSentence.withoutHtmlTags.count
                            }
                            if lang == defaultLang {
                                var partitionInfo = TimeFrameInfo(parsedText[i], idx: i)
                                partitionInfo.paragraphLocation = NSRange(location: currentLocation, length: currentLength)
                                paragraphContents[itemIdx].partitionInfos.append(partitionInfo)
                                currentLocation += currentLength                        }
                        }
                    }
                    translationIdx = paragraphContents[itemIdx].segmentIdx + 1
                    paragraphContents[itemIdx].partitionInfos = paragraphContents[itemIdx].partitionInfos.filter { info in
                        return info.paragraphLocation.length > 0
                    }
                }
            }
            content = parsedText
        
            let resources = try container.decode([String: Any].self, forKey: .resources)
            let audioResourceInfo = KPSAudioFileInfo(info: resources[audioResourceId] as! [String: Any])
            length = audioResourceInfo.duration
            streamingUrl = URL(string: audioResourceInfo.streamingUrl)!
        } else {
            error = isPublic ? .needPurchase : .needLogin
        }
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

public struct KPSAudioTextInfo: Decodable {
    public let type: String
    public let end, start: TimeValue

}

public struct KPSAudioFileInfo {
    public let duration: Double
    public let streamingUrl: String
    
    init(info: [String: Any]) {
        duration = info["duration"] as! Double
        streamingUrl = info["streamingUrl"] as! String
    }
}

public struct KPSAudioText {
    
    public let type: String
    public let segmentIdx: Int
    public let defaultLang: String
    public let startTime, endTime: Double
    public var translation: [String: String]
    
    init(info: KPSAudioTextInfo, idx: Int, lang: String) {
        
        type = info.type
        segmentIdx = idx
        startTime = info.start.doubleValue
        endTime = info.end.doubleValue
        
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

internal struct TimeFrameInfo {
    public let startTime, endTime: Double
    public let mappingIdx: Int
    
    init(_ info: KPSAudioText, idx: Int) {
        startTime = info.startTime
        endTime = info.endTime
        mappingIdx = idx
    }
}

public enum TimeValue: Decodable {
    
    case int(Int), double(Double)
    
    public init(from decoder: Decoder) throws {
        if let int = try? decoder.singleValueContainer().decode(Int.self) {
            self = .int(int)
            return
        }
        if let double  = try? decoder.singleValueContainer().decode(Double.self) {
            self = .double(double)
            return
        }
        
        throw TimeValueError.missingValue
    }
    
    public var doubleValue: Double {
        switch self {
        case .int(let value):
            return Double(value)
        case .double(let value):
            return value
        }
    }
    enum TimeValueError: Swift.Error {
        case missingValue
    }
}

