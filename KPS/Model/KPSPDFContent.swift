//
//  KPSPDFContent.swift
//  KPS
//
//  Created by Kono on 2022/6/8.
//

public struct KPSPDFContent: Decodable {
    public let orderPageIncreaseRight: Bool
    public let startPageInParent: Int
    public let pages: [KPSPDFPage]

    enum CodingKeys: String, CodingKey {
        case orderPageIncreaseRight, startPageInParent, pages
    }
    
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        orderPageIncreaseRight = try container.decode(Bool.self, forKey: .orderPageIncreaseRight)
        startPageInParent = try container.decode(Int.self, forKey: .startPageInParent)
        pages = try container.decode([KPSPDFPage].self, forKey: .pages)

    }
}

public struct KPSPDFPage: Decodable {
    public let bgColor: KPSPDFPageInfoBGColor
    public let version: String
    public let fgs, bgs: [KPSPDFPageInfoComponent]
    public let paddingTop: Double

    enum CodingKeys: String, CodingKey {
        case bgColor, version, fgs, bgs, paddingTop
    }
    
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        bgColor = try container.decode(KPSPDFPageInfoBGColor.self, forKey: .bgColor)
        version = try container.decode(String.self, forKey: .version)
        fgs = try container.decode([KPSPDFPageInfoComponent].self, forKey: .fgs)
        bgs = try container.decode([KPSPDFPageInfoComponent].self, forKey: .bgs)
        paddingTop = try container.decode(Double.self, forKey: .paddingTop)

    }
    
}

public struct KPSPDFPageInfoBGColor: Decodable {
    public let r, g, b: Int

    enum CodingKeys: String, CodingKey {
        case r, g, b
    }
}

public struct KPSPDFPageInfoComponent: Decodable {
    public let resourceId: String
    public let position: KPSPDFPageInfoComponentPosition

    enum CodingKeys: String, CodingKey {
        case resourceId, position
    }
}

public struct KPSPDFPageInfoComponentPosition: Decodable {
    public let width, top, left: Double

    enum CodingKeys: String, CodingKey {
        case width, top, left
    }
    
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            width = try container.decode(Double.self, forKey: .width)
        } catch {
            let dataWidth = try container.decode(Int.self, forKey: .width)
            width = Double(dataWidth)
        }
        
        do {
            top = try container.decode(Double.self, forKey: .top)
        } catch {
            let dataTop = try container.decode(Int.self, forKey: .top)
            top = Double(dataTop)
        }
        
        do {
            left = try container.decode(Double.self, forKey: .left)
        } catch {
            let dataLeft = try container.decode(Int.self, forKey: .left)
            left = Double(dataLeft)
        }
        
    }
}

