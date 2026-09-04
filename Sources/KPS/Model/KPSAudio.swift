//
//  KPSAudio.swift
//  KPS
//
//  Created by mingshing on 2021/8/18.
//

import Foundation

public struct KPSAudioContent {
    
    enum CodingKeys: String, CodingKey {
        case error, contentNode, puser, siblingNodes, parentNode
    }
    
    enum RootKeys: String, CodingKey {
        case id, type, name, description, orderInParent, info
        case customData
        case publicData = "public"
        case free
        case covers
        case resources, content
        case permissions
    }
    
    enum InfoKeys: String, CodingKey {
        case authors
    }
    
    enum CoverKeys: String, CodingKey {
        case list
    }
    
    enum ContentDataKeys: String, CodingKey {
        case textSegments, languages, audioLanguage, duration, resource
    }
    
    enum imageContainerKeys: String, CodingKey {
        case list
    }
    
    public var parent: KPSContentMeta?
    public var siblings: [KPSContentMeta]?
    public let id, type: String
    public let name, description: [String: String]
    public let authors: [String: [String]]
    public var coverImages: [KPSImageResource] = []
    public let order: Int
    public let isPublic, isFree: Bool
    public var length: Double?
    public var customData: [String: Any]?
    public var permissions: [String: Bool]?
    public var content: [KPSAudioText] = []
    public var paragraphContents: [KPSAudioText] = []
    internal var timeFrames: [TimeFrameInfo] = []
    public var streamingUrl: URL?
    public var collectionId: String?
    public var collectionName: [String: String]?
    public var collectionImage: KPSImageResource?
    public var errorDescription: String?
    public var error: KPSContentError?
    public var firstAuthor: [String: String] {
        var res = [String: String]()
        for key in authors.keys {
            res[key] = authors[key]?.first ?? ""
        }
        return res
    }
    public var puser: KPSUserModel?
}

extension KPSAudioContent: Decodable {
    
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        let errorDescription = try baseContainer.decodeIfPresent(String.self, forKey: .error)
        
        let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .contentNode)
        puser = try baseContainer.decodeIfPresent(KPSUserModel.self, forKey: .puser)
        if let user = puser {
            KPSClient.shared.isUserBlocked = user.status == 0
        }
        parent = try baseContainer.decodeIfPresent(KPSContentMeta.self, forKey: .parentNode)
        siblings = try baseContainer.decodeIfPresent([KPSContentMeta].self, forKey: .siblingNodes)
        
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode([String: String].self, forKey: .name)
        description = try container.decode([String: String].self, forKey: .description)
        order = try container.decode(Int.self, forKey: .orderInParent)
        isPublic = try container.decode(Bool.self, forKey: .publicData)
        isFree = try container.decode(Bool.self, forKey: .free)
        customData = try container.decodeIfPresent([String: Any].self, forKey: .customData)
        permissions = try container.decodeIfPresent([String: Bool].self, forKey: .permissions)
        
        if let _ = try container.decodeIfPresent([String: Any].self, forKey: .info) {
            let infoDataContainer = try container.nestedContainer(keyedBy: InfoKeys.self, forKey: .info)
            authors = try infoDataContainer.decodeIfPresent([String: [String]].self, forKey: .authors) ?? [:]
        } else {
            authors = [:]
        }
        
        let resources = try container.decode([String: KPSResourceType].self, forKey: .resources)
        
        if let _ = try container.decodeIfPresent([String: Any].self, forKey: .covers) {
            let coverIdContainer = try container.decode([String:[String]].self, forKey: .covers)
            let coverResourceIds = coverIdContainer["list"]!
            
            var images: [KPSImageResource] = []
            
            for id in coverResourceIds {
                if case .IMAGE(let imageResource) = resources[id] {
                    images.append(imageResource)
                }
            }
            coverImages = images
        }
        
        let contentDataContainer = try container.nestedContainer(keyedBy: ContentDataKeys.self, forKey: .content)
        let defaultLang = try contentDataContainer.decode(String.self, forKey: .audioLanguage)
        
        var textTypeInfos: [KPSAudioTextInfo] = []
        var textLangInfos: [String: Any] = [:]
        
        if let textSegments =  try contentDataContainer.decodeIfPresent([KPSAudioTextInfo].self, forKey: .textSegments) {
            textTypeInfos = textSegments
        }
        if let textLanguages = try contentDataContainer.decodeIfPresent([String : Any].self, forKey: .languages) {
            textLangInfos = textLanguages
        }
        
        var parsedText = [KPSAudioText]()

        // MARK: Handle audio resource info (premium content)
        if errorDescription == nil {
            let audioResourceId = try contentDataContainer.decode(String.self, forKey: .resource)
            
            if case .AUDIO(let audioResource) = resources[audioResourceId] {
                length = audioResource.duration
                streamingUrl = URL(string: audioResource.streamingUrl)!
            }
        
        } else {
            length = try contentDataContainer.decode(Double.self, forKey: .duration)
        }
        
        // MARK: Handle content info
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
            var opSentenceIdx: Int = 0
            
            for paragraphIdx in 0..<paragraphContents.count {
                var currentLocation = 0
                var currentSentenceLength = 0
                let maxSentenceIdx = paragraphContents[paragraphIdx].segmentIdx
                
                for i in opSentenceIdx...maxSentenceIdx {
                    
                    if let sentence = translation[i]["content"] {
                        let trimmed = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
                        currentSentenceLength = trimmed.withoutHtmlTags.count
                        if paragraphContents[paragraphIdx].translation[lang] == nil {
                            paragraphContents[paragraphIdx].translation[lang] = trimmed

                        } else {
                            var nextSentence: String = trimmed
                            
                            if !paragraphContents[paragraphIdx].translation[lang]!.isEmpty {
                                nextSentence = " " + nextSentence
                                currentLocation += 1
                            }
                            paragraphContents[paragraphIdx].translation[lang]! += nextSentence

                        }
                        currentLocation += currentSentenceLength
                        
                        if lang == defaultLang {
                            let sentenceStartPosition = currentLocation - trimmed.withoutHtmlTags.count
                            
                            // parse the sentence timeframe info
                            var partitionInfo = TimeFrameInfo(parsedText[i], idx: i)
                            partitionInfo.paragraphLocation = NSRange(location: sentenceStartPosition, length: currentSentenceLength)
                            paragraphContents[paragraphIdx].partitionInfos.append(partitionInfo)
                        }
                    }
                }
                opSentenceIdx = paragraphContents[paragraphIdx].segmentIdx + 1
                paragraphContents[paragraphIdx].partitionInfos = paragraphContents[paragraphIdx].partitionInfos.filter { info in
                    return info.paragraphLocation.length > 0
                }
            }
        }
        content = parsedText
    }
    
    public init (url: URL) {
        
        streamingUrl = url
        id = ""
        type = "Invalid"
        name = [String: String]()
        description = [String: String]()
        authors = [String: [String]]()
        length = 0.0
        order = -1
        isPublic = false
        isFree = false
        customData = [String: Any]()
        content = [KPSAudioText]()
        
    }
    
}

private func parsedWordTimeFrames(sentences: [[String: Any]]) -> [TimeFrameInfo] {
    
    var res: [TimeFrameInfo] = []
    
    for sentence in sentences {
        
        if let wordRawInfos = sentence["words"] as? [[String: Any]] {
            
            for wordRawInfo in wordRawInfos {
                guard let _ = wordRawInfo["word"],
                      let _ = wordRawInfo["start"],
                      let _ = wordRawInfo["end"] else { continue }
                res.append(TimeFrameInfo(wordRawInfo))
            }
        }
    }
    
    return res
}

public struct KPSAudioTextInfo: Decodable {
    public let type: String
    public let end, start: TimeValue

}

public struct KPSAudioText {
    
    public var type: String
    public var segmentIdx: Int
    public let defaultLang: String
    public var startTime, endTime: Double
    public var translation: [String: String]
    internal var partitionInfos: [TimeFrameInfo]
    
    init(info: KPSAudioTextInfo, idx: Int, lang: String) {
        
        type = info.type
        segmentIdx = idx
        startTime = info.start.doubleValue
        endTime = info.end.doubleValue
        
        defaultLang = lang
        translation = [String: String]()
        partitionInfos = [TimeFrameInfo]()
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
    public var startTime, endTime: Double
    public let mappingIdx: Int
    public let text: String
    public var paragraphLocation: NSRange
    
    init(_ info: KPSAudioText, idx: Int) {
        startTime = info.startTime
        endTime = info.endTime
        mappingIdx = idx
        text = info.text
        paragraphLocation = NSRange(location: 0, length: info.text.count)
    }
    
    init(_ wordInfo: [String: Any]) {
        //Hack for sync issue
        let start = (wordInfo["start"] as! NSNumber).doubleValue + 0.02
        let end = (wordInfo["end"] as! NSNumber).doubleValue + 0.02
        startTime = start
        endTime = start == end ? end + 0.05 : end
        text = wordInfo["word"] as! String
        
        
        mappingIdx = -1
        paragraphLocation = NSRange(location: 0, length: text.count)
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

