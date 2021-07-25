//
//  KPSContent.swift
//  KPS


public struct KPSContent: Codable {
    
    let id: String
    //let customData: [String: Any]
    //let images: [KPSImage]
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        //case images
    }
}

public struct KPSImage: Codable {
    
    let width: Int
    let height: Int
    
    
    enum CodingKeys: String, CodingKey {
        case width
        case height
    }
    
    func getUri(targetWidth: Int) -> String {
        
        return "hello \(targetWidth)"
    }
}
