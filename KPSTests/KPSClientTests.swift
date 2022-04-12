//
//  KPSClientTests.swift
//  KPSTests
//
//  Created by mingshing on 2021/7/30.
//

import XCTest
import Moya
@testable import KPS


class KPSClientTests: XCTestCase {

    let appKey = "test_key"
    let appId = "test_id"
    let kpsAPIVersion = "test"
    
    
    var stubbingProvider: MoyaProvider<CoreAPIService>!
    var stubClient: KPSClient!
    
    override func setUp() {
        
    }

    func testDevClientInit() {
        
        KPSClient.config = .init(apiKey: appKey, appId: appId, server: .develop())
        XCTAssertEqual(KPSClient.config.baseServer.baseUrl.absoluteString, "https://kps-dev.thekono.com/api/v1")
        XCTAssertEqual(KPSClient.config.baseServer.projectUrl.absoluteString, "https://kps-dev.thekono.com/api/v1/projects/\(appId)")
    }
    
    func testStagClientInit() {
        KPSClient.config = .init(apiKey: appKey, appId: appId, server: .staging())
        XCTAssertEqual(KPSClient.config.baseServer.baseUrl.absoluteString, "https://kps-stg.thekono.com/api/v1")
        XCTAssertEqual(KPSClient.config.baseServer.projectUrl.absoluteString, "https://kps-stg.thekono.com/api/v1/projects/\(appId)")
    }
    
    
    func testClientInit() {
        
        KPSClient.config = .init(apiKey: appKey, appId: appId)
        XCTAssertEqual(KPSClient.shared.apiKey, appKey)
        XCTAssertEqual(KPSClient.shared.appId, appId)
        XCTAssertEqual(KPSClient.config.baseServer.baseUrl.absoluteString, "https://kps.thekono.com/api/v1")
        XCTAssertEqual(KPSClient.config.baseServer.projectUrl.absoluteString, "https://kps.thekono.com/api/v1/projects/\(appId)")
    }
    
    func testLoginSucceed() {
        
        let access_token = "mockToken"
        let access_id = "mockUserId"
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.login(keyID: access_id, token: access_token, completion: {result in })
        XCTAssertEqual(stubClient.currentUserId, "testUser")
        XCTAssertTrue(stubClient.isUserLoggedIn)
        XCTAssertEqual(stubClient.userPermissions.count, 2)
    }
    
    func testLoginFailedInvalidUser() {
        
        let access_token = "mockToken"
        let access_id = "mockUserId"
        let responseData = "{\"error\": \"kid does not exist\"}".utf8Encoded
        let customFailedEndpointClosure = { (target: CoreAPIService) -> Endpoint in
            return Endpoint(url: URL(target: target).absoluteString,
                            sampleResponseClosure: { .networkResponse(404, responseData) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers)
        }

        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customFailedEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.login(keyID: access_id, token: access_token) { result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                XCTAssertEqual(error.response?.statusCode, 404)
                break
            default: break
            }
        }
        
    }
    
    func testLogoutSucceed() {
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.logout(completion: {result in})
        XCTAssertFalse(stubClient.isUserLoggedIn)
    }
    
    func testLogoutFailed() {
        
        let responseData = "{\"error\": \"server unreachable\"}".utf8Encoded
        let customFailedEndpointClosure = { (target: CoreAPIService) -> Endpoint in
            return Endpoint(url: URL(target: target).absoluteString,
                            sampleResponseClosure: { .networkResponse(500, responseData) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers)
        }

        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customFailedEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.logout(){ result in
            switch result {
            case .failure(let error):
                XCTAssertNotNil(error)
                do {
                    let errorDescription = try error.response?.mapJSON() as! [String: String]
                    XCTAssertEqual(errorDescription["error"], "server unreachable")
                } catch {
                    
                }
                break
            default:
                break
            }
        }
    }
    
    func testFetchRootFolderSucceed() {
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.fetchCollection { result in
            switch result {
            case .success(let collection):
                XCTAssertNotNil(collection.id)
                XCTAssertGreaterThan(collection.children.count, 0)
            case .failure(_):
                XCTAssert(false)
            }
        }
    }
    
    func testFetchFolderSucceed() {
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = KPSClient(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        let mockFolderId = "61dbb2cc2422e40a2cd63e8a"
        stubClient.fetchCollection(Id: mockFolderId) { result in
            switch result {
            case .success(let collection):
                XCTAssertNotNil(collection.id)
                XCTAssertEqual(collection.type, "folder")
                XCTAssertEqual(collection.metaData.order, 10)
                XCTAssertGreaterThan(collection.children.count, 0)
            case .failure(_):
                XCTAssert(false)
            }
        }
    }
    
    
    func customSuccessEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        return Endpoint(url: URL(target: target).absoluteString,
                        sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers)
    }
    
    
}
