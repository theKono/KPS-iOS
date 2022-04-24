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
    
    override func setUp() {
        
    }

    func testPurchaseConfigSuccess() {
        
        KPSPurchases.configure(withServerUrl: mockEndpointURL)
        XCTAssertTrue(KPSPurchases.isConfigured)
    }
    
    func testGetCurrentCustomerTypeSuccess() {
        
        
        stubbingProvider = MoyaProvider<PurchaseAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        KPSPurchases.configure(withServerUrl: "test_url")
        sut = KPSPurchases.shared
        sut.getCurrentCustomerType { type in
            XCTAssertEqual(type, .New)
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
