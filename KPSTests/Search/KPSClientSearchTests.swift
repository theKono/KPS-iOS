//
//  KPSClientSearchTests.swift
//  KPSTests
//
//  Created by Kono on 2023/5/25.
//

import XCTest
import Moya
@testable import KPS

final class KPSClientSearchTests: XCTestCase {

    let appKey = "test_key"
    let appId = "test_id"
    let kpsAPIVersion = "test"
    
    var sut: KPSClient!
    var stubbingProvider: MoyaProvider<CoreAPIService>!
    var mockMediaDelegate = KPSClientMediaContentDelegateMock()
    
    override func setUp() {
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        sut = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        sut.mediaContentDelegate = mockMediaDelegate
    }
    
    func customSuccessEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(200, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }

    // MARK: Search test
    func testSearchContentSuccess() {
        let mockKeyword = "癌症"
        sut.search(with: mockKeyword) { result in
            switch result {
            case .success(let searchResult):
                
                XCTAssertNil(searchResult.error)
                XCTAssertNotNil(searchResult.result)
                
                break
            default: break
            }
        }
        
    }
}
