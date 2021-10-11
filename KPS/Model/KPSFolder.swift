//
//  KPSFolder.swift
//  KPS
//


public struct KPSFolder {
    
    enum CodingKeys: String, CodingKey {
        case folder, children, error
    }
    enum RootKeys: String, CodingKey {
        case id,type,name,description
    }
    
    public var children: [KPSContent]
    public var id, type, name, description: String?
}

extension KPSFolder: Decodable {
    public init(from decoder: Decoder) throws {

        let baseContainer = try decoder.container(keyedBy: CodingKeys.self)
        children = try baseContainer.decode([KPSContent].self, forKey: .children)
        
        if let _ = try baseContainer.decodeIfPresent([String: Any].self, forKey: .folder) {
            let container = try baseContainer.nestedContainer(keyedBy: RootKeys.self, forKey: .folder)
            id = try container.decode(String.self, forKey: .id)
            type = try container.decode(String.self, forKey: .type)
            name = try container.decode(String.self, forKey: .name)
            description = try container.decode(String.self, forKey: .description)
        }
    }

}
