//
//  KPSCouponResponse.swift
//  KPS
//
//  Created by Kono on 2022/9/6.
//

import Foundation

public struct KPSCouponResponse: Decodable {
    public let error: String?
    public let coupon: KPSCoupon?
}

public struct KPSCoupon: Decodable {
    public let code: String
    public let campaign: String
    public let timeLength: Double //毫秒
    public let plan: String
    public let transactionName: String
    public let periodStart: TimeInterval
    public let periodEnd: TimeInterval

    enum CodingKeys: String, CodingKey {
        case code, campaign, timeLength, plan, transactionName
        case periodStart = "start"
        case periodEnd = "end"
    }
}
