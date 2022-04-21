//
//  KPSPurchaseTransaction.swift
//  KPS
//
//  Created by mingshing on 2022/4/12.
//

import Foundation

public struct KPSPurchaseTransaction {
    
    enum CodingKeys: String, CodingKey {
        case transactionId, appEnv, plan, createTime, expireTime, type, interupted, interuptedTime, promotionId
    }
    
    public var id: String
    public var appEnv: String?
    public var plan: String
    public var begin: TimeInterval
    public var end: TimeInterval
    public var type: String
    public var promotionId: String?
    public var interruptedType: String?
    public var interruptedTime: TimeInterval?
    public var isTrial: Bool {
        if let promotionId = promotionId {
            if promotionId == "trial_offer" {
                return true
            }
        }
        return false
    }
    
}

extension KPSPurchaseTransaction: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .transactionId)
        appEnv = try container.decodeIfPresent(String.self, forKey: .appEnv)
        plan = try container.decode(String.self, forKey: .plan)
        begin = try container.decode(TimeInterval.self, forKey: .createTime)
        end = try container.decode(TimeInterval.self, forKey: .expireTime)
        if let interruptedTime = try container.decodeIfPresent(TimeInterval.self, forKey: .interuptedTime) {
            end = interruptedTime
        }
        type = try container.decode(String.self, forKey: .type)
        promotionId = try container.decodeIfPresent(String.self, forKey: .promotionId)
        interruptedType = try container.decodeIfPresent(String.self, forKey: .interupted)
        interruptedTime = try container.decodeIfPresent(TimeInterval.self, forKey: .interuptedTime)
    }
}
