//
//  KPSResourceType.swift
//  KPS
//
//  Created by Kono on 2022/6/8.
//

public enum KPSResourceType {
    case IMAGE(KPSImageResource)
    case FILE(KPSFileResource)
    case AUDIO(KPSAudioResource)
    
    enum PredictKeys: String, CodingKey {
        case type
    }
    
    enum TargetObjectType: String, Decodable {
        case IMAGE
        case FILE
        case AUDIO
    }
    
    public var srcURL: String {
        switch self {
        case .IMAGE(let imageResource):
            return imageResource.mainImageURL
        case .FILE(let fileResource):
            return fileResource.url
        case .AUDIO(let audioResource):
            return audioResource.streamingUrl
        }
    }
}

extension KPSResourceType: Decodable {
    
    public init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()
        
        let container = try decoder.container(keyedBy: PredictKeys.self)
        let targetObjectType = try container.decode(TargetObjectType.self, forKey: .type)
        
        switch targetObjectType {
        case .IMAGE:
            self = try .IMAGE(singleValueContainer.decode(KPSImageResource.self))
        case .FILE:
            self = try .FILE(singleValueContainer.decode(KPSFileResource.self))
        case .AUDIO:
            self = try .AUDIO(singleValueContainer.decode(KPSAudioResource.self))
            
        }
    }
}
