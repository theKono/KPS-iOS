//
//  KPSPurchaseOrder.swift
//  KPS
//
//  Created by mingshing on 2022/4/12.
//

import Foundation
public struct KPSPurchaseOrder {
    
    enum CodingKeys: String, CodingKey {
        case orderId, appleEnv, plan, ownerId, createTime, type, tentativeNextRenewalPlan, nextRenewalGracePeriod, pauseResumeTime, latestTransaction
    }
    
    public var id: String
    public var appleEnv: String?
    public var ownerId: String
    public var createTime: TimeInterval
    public var type: String
    public var nextPlan: String?
    public var gracePeriodEnd: TimeInterval?
    public var pauseResumeTime: TimeInterval?
    public var latestTransaction: KPSPurchaseTransaction
    public var provider: SubscriptionProvider {
        return SubscriptionProvider(rawValue: type) ?? .kps
    }
}

extension KPSPurchaseOrder: Decodable {
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .orderId)
        appleEnv = try container.decodeIfPresent(String.self, forKey: .appleEnv)
        ownerId = try container.decode(String.self, forKey: .ownerId)
        createTime = try container.decode(TimeInterval.self, forKey: .createTime)
        type = try container.decode(String.self, forKey: .type)
        nextPlan = try container.decodeIfPresent(String.self, forKey: .tentativeNextRenewalPlan)
        gracePeriodEnd = try container.decodeIfPresent(TimeInterval.self, forKey: .nextRenewalGracePeriod)
        pauseResumeTime = try container.decodeIfPresent(TimeInterval.self, forKey: .pauseResumeTime)
        latestTransaction = try container.decode(KPSPurchaseTransaction.self, forKey: .latestTransaction)
    }
}
