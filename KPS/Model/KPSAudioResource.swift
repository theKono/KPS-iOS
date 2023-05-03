//
//  KPSAudioResource.swift
//  KPS-iOS
//
//  Created by Kono on 2023/5/3.
//

import Foundation

public struct KPSAudioResource: Decodable {
    public let type: String
    public let duration: Double
    public let streamingUrl: String
    public var sentences: [[String: Any]] = []

    enum CodingKeys: String, CodingKey {
        case type, duration, streamingUrl, sentences
    }

}

extension KPSAudioResource {

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(String.self, forKey: .type)
        do {
            duration = try container.decode(Double.self, forKey: .duration)
        } catch {
            let durationInt = try container.decode(Int.self, forKey: .duration)
            duration = Double(durationInt)
        }
        streamingUrl = try container.decode(String.self, forKey: .streamingUrl)
        
        var sentencesRes: [[String: Any]] = []
        let tempSentences = try container.decodeIfPresent([Any].self, forKey: .sentences) ?? []
        for tempSentence in tempSentences {
            if let sentence = tempSentence as? [String: Any] {
                sentencesRes.append(sentence)
            }
        }
        sentences = sentencesRes
    }
}

