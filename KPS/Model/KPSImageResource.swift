//
//  KPSImageResource.swift
//  KPS
//
//  Created by mingshing on 2021/9/11.
//

public struct KPSImageResource {
    
    public let width, height: Int
    public let thumbnailSizes: [Int]
    public let urls: [String: String]
    public let webpUrls: [String: String]

    public var mainImageURL: String {
        if let maxImageSize = thumbnailSizes.last {
            return urls[String(maxImageSize)] ?? ""
        }
        return ""
    }
    
    public func thumbnailImageURL(of targetWidth: Int) -> String {
        
        if let maxWidth = thumbnailSizes.last {
            var enoughWidth = maxWidth
            for i in 0..<thumbnailSizes.count {
                if thumbnailSizes[i] > targetWidth {
                    enoughWidth = thumbnailSizes[i]
                    break
                }
            }
            return urls[String(enoughWidth)] ?? ""
        }
        return ""
    }

    enum CodingKeys: String, CodingKey {
        case type, width, height, thumbnails, urls, webpUrls
    }

}

extension KPSImageResource: Decodable {

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        let supportThumbnailSizes = try container.decode([Int].self, forKey: .thumbnails)
        thumbnailSizes = supportThumbnailSizes.sorted()
        urls = try container.decode([String: String].self, forKey: .urls)
        webpUrls = try container.decode([String: String].self, forKey: .webpUrls)
    }
}
