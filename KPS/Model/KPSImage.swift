//
//  KPSImage.swift
//  KPS
//
//  Created by mingshing on 2021/8/12.
//
public struct KPSImage {
    
    public let id, uri: String
    public let width, height: Int
    public let thumbnailSizes: [Int]

    public var mainImageURL: String {
        return (config?.baseUrl.absoluteString ?? "") + "/" + uri
    }
    
    public func thumbnailImageURL(of targetWidth: Int) -> String {
        
        var enoughWidth = thumbnailSizes.last
        for i in 0..<thumbnailSizes.count {
            if thumbnailSizes[i] > targetWidth {
                enoughWidth = thumbnailSizes[i]
                break
            }
        }
        var url: String = ""
        if let index = uri.lastIndex(of: ".") {
            let head = uri.prefix(upTo: index)
            let fileType = uri.suffix(from: index)
            let bucketName = "kps_public_" + (config?.env ?? "dev") + "_thumbnails/"
            url = (config?.cloudStorage ?? "") + bucketName + head + "-" + String(enoughWidth ?? 0) + fileType
            
        }
        return url
    }
    
    var config: Server?
    enum CodingKeys: String, CodingKey {
        case id, width, height, thumbnails, uri
    }

}

extension KPSImage: Decodable {

    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        width = try container.decode(Int.self, forKey: .width)
        height = try container.decode(Int.self, forKey: .height)
        let supportThumbnailSizes = try container.decode([Int].self, forKey: .thumbnails)
        thumbnailSizes = supportThumbnailSizes.sorted()
        uri = try container.decode(String.self, forKey: .uri)

    }
}
