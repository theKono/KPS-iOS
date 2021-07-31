//
//  KPSFolder.swift
//  KPS
//


public struct KPSFolder {
    
    enum CodingKeys: String, CodingKey {
        case article, children, error
    }
    
    public var children: [KPSContent]
    
}

extension KPSFolder: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        children = try container.decode([KPSContent].self, forKey: .children)
        
    }

}
