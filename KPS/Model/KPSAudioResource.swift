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
        sentences = try container.decode([[String: Any]].self, forKey: .sentences)
    }
}

