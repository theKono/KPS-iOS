//
//  KPSClientArticleTests.swift
//  KPSTests
//
//  Created by Kono on 2022/5/31.
//

import XCTest
import AVFoundation
import Moya
@testable import KPS

class KPSClientArticleTests: XCTestCase {
    
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
    
    override func tearDown() {
    }
    
    // MARK: Fetch data source test
    func testFetchArticleContentSuccess() {
        let mockArticleId = "62625d6b5b1b1106e55d31f0"
        sut.fetchArticleContent(Id: mockArticleId) { result in
            switch result {
            case .success(let articleContent):
                XCTAssertTrue(articleContent.isFree)
                XCTAssertFalse(articleContent.isPublic)
                XCTAssertEqual(articleContent.type, "article")
                break
            default: break
            }
        }
        
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

}
