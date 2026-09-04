//
//  KPSPurchaseTests.swift
//  KPSTests
//
//  Created by mingshing on 2022/4/12.
//

import XCTest
import Moya
@testable import KPS

class KPSPurchaseTests: XCTestCase {

    var stubbingProvider: MoyaProvider<PurchaseAPIService>!
    var sut: KPSPurchases!
    
    let mockDelegate: KPSPurchasesDelegate = KPSPurchaseDelegateMock()
    let mockEndpointURL: String = "https://purchase.thekono.com"
    let mockEnpointSessionKey: String = "session_key"
    
    override func setUp() {
        stubbingProvider = MoyaProvider<PurchaseAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        KPSPurchases.configure(withServerUrl: mockEndpointURL, sessionKey: mockEnpointSessionKey)
        sut = KPSPurchases.shared
    }

    func testPurchaseConfigSuccess() {
        
        KPSPurchases.configure(withServerUrl: mockEndpointURL, sessionKey: mockEnpointSessionKey)
        XCTAssertTrue(KPSPurchases.isConfigured)
    }
    
    func testGetCurrentCustomerTypeSuccess() {
        
        sut.getCurrentCustomerType { type in
            XCTAssertEqual(type, .New)
        }
        
    }
    
    func testRedeemCouponSuccess() {
               
        let mockArticleId = "redeemCouponTest"
        sut.redeemCoupon(code: mockArticleId) { result in
            switch result {
            case .success(let couponInfo):
                
                XCTAssertEqual(couponInfo.coupon?.code, "2IEG3H79BFBVV8O7WV")
                XCTAssertEqual(couponInfo.coupon?.campaign, "2022 events")
                XCTAssertEqual(couponInfo.coupon?.timeLength, 86400)
                XCTAssertEqual(couponInfo.coupon?.plan, "1 日 Coupon")
                XCTAssertEqual(couponInfo.coupon?.transactionName, "coupon")
                XCTAssertEqual(couponInfo.coupon?.periodStart, 1661765892000)
                XCTAssertEqual(couponInfo.coupon?.periodEnd, 1662111492000)
                XCTAssertNil(couponInfo.error)
                break
            default: break
            }
        }
    }
    
    func testRedeemCouponWithError() {
        let mockArticleId = "redeemCouponWithError"
        sut.redeemCoupon(code: mockArticleId) { result in
            switch result {
            case .success(let couponInfo):
                
                XCTAssertEqual(couponInfo.error, "coupon not found")
                XCTAssertNil(couponInfo.coupon)
                break
            default: break
            }
        }
    }

    func customSuccessEndpointClosure(_ target: PurchaseAPIService) -> Endpoint {
        return Endpoint(url: URL(target: target).absoluteString,
                        sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers)
    }
    
}
