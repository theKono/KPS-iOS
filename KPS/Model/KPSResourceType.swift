//
//  KPSResourceType.swift
//  KPS
//
//  Created by Kono on 2022/6/8.
//

public enum KPSResourceType {
    case IMAGE(KPSImageResource)
    case FILE(KPSFileResource)
    
    public var srcURL: String {
        switch self {
        case .IMAGE(let imageResource):
            return imageResource.mainImageURL
        case .FILE(let fileResource):
            return fileResource.url
        }
    }
}

extension KPSResourceType: Decodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = try .IMAGE(container.decode(KPSImageResource.self))
        } catch {
            do {
                self = try .FILE(container.decode(KPSFileResource.self))
            }
        }
    }
}
