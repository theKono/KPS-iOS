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
        let mockArticleId = "articleContentTest"
        sut.fetchArticleContent(Id: mockArticleId) { result in
            switch result {
            case .success(let articleContent):
                
                XCTAssertEqual(articleContent.id, "62995c9ee9a2b3c63280d9b5")
                XCTAssertEqual(articleContent.type, "article")
                XCTAssertEqual(articleContent.name["zh-TW"], "pdf test 1")
                XCTAssertEqual(articleContent.description["zh-TW"], "pdf test description")
                XCTAssertEqual(articleContent.authors["zh-TW"]?.first, "qwer")
                XCTAssertEqual(articleContent.order, 4)
                XCTAssertEqual(articleContent.coverList.count, 1)
                
                XCTAssertFalse(articleContent.isFree)
                XCTAssertFalse(articleContent.isPublic)
                XCTAssertNotNil(articleContent.permissions?["VIP"])
                
                XCTAssertNotNil(articleContent.customData)
                XCTAssertNil(articleContent.fitReadingData)
                XCTAssertNotNil(articleContent.pdfData)
                XCTAssertNotNil(articleContent.resources)
                
                XCTAssertNil(articleContent.parent)
                XCTAssertNil(articleContent.siblings)
                
                XCTAssertNil(articleContent.error)
                XCTAssertNil(articleContent.errorDescription)
                
                break
            default: break
            }
        }
        
    }
    
    func testFetchArticleContentWithoutPermission() {
        let mockArticleId = "articleContentWithoutPermission"
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customUserNotLoginErrorEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        sut = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        sut.fetchArticleContent(Id: mockArticleId) { result in
            switch result {
            case .success(let articleContent):
                XCTAssertEqual(articleContent.error, .needLogin)
                break
            default:
                XCTAssert(false)
                break
            }
        }
    }
    
    func testFetchArticleContentWithWrongArticleId() {
        let mockArticleId = "articleContentWithWrongArticleId"
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customContentNotFoundErrorEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        sut = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        sut.fetchArticleContent(Id: mockArticleId) { result in
            switch result {
            case .failure(let error):
                switch error {
                case .statusCode(let response):
                    XCTAssertEqual(response.statusCode, 404)
                default:
                    XCTAssert(false)
                }
                break
            default:
                XCTAssert(false)
                break
            }
        }
        
    }
    
    func testFetchArticleContentWithoutNetwork() {
        let mockArticleId = "articleContentWithNetworkError"
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customNetworkErrorEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)

        sut = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        sut.fetchArticleContent(Id: mockArticleId) { result in
            
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                XCTAssertNil(error.response)
                break
            default:
                XCTAssert(false)
                break
            }
        }
        
    }
    
    func customUserNotLoginErrorEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(401, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }
    
    func customContentNotFoundErrorEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkResponse(404, target.sampleData) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
    }
    
    func customNetworkErrorEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        return Endpoint(
            url: URL(target: target).absoluteString,
            sampleResponseClosure: { .networkError(error) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
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
