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
    var stubClient: Client!
    
    override func setUp() {
        
    }

    func testDevClientInit() {
        
        Client.config = .init(apiKey: appKey, appId: appId, server: .develop(appId: appId, version: kpsAPIVersion))
        XCTAssertEqual(Client.config.baseServer.baseUrl.absoluteString, "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(kpsAPIVersion)")
        XCTAssertEqual(Client.config.baseServer.projectUrl.absoluteString, "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(kpsAPIVersion)/projects/\(appId)")
    }
    
    func testStagClientInit() {
        Client.config = .init(apiKey: appKey, appId: appId, server: .staging(appId: appId, version: kpsAPIVersion))
        XCTAssertEqual(Client.config.baseServer.baseUrl.absoluteString, "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(kpsAPIVersion)")
        XCTAssertEqual(Client.config.baseServer.projectUrl.absoluteString, "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v\(kpsAPIVersion)/projects/\(appId)")
    }
    
    
    func testClientInit() {
        
        Client.config = .init(apiKey: appKey, appId: appId)
        XCTAssertEqual(Client.shared.apiKey, appKey)
        XCTAssertEqual(Client.shared.appId, appId)
        XCTAssertEqual(Client.config.baseServer.baseUrl.absoluteString, "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v1")
        XCTAssertEqual(Client.config.baseServer.projectUrl.absoluteString, "https://kps-server-ojx42ulvaa-uc.a.run.app/platform/api/v1/projects/\(appId)")
    }
    
    func testLoginSucceed() {
        
        let access_token = "mockToken"
        let access_id = "mockUserId"
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.login(keyID: access_id, token: access_token, completion: {result in })
        XCTAssertEqual(stubClient.currentUserId, "testUser")
        XCTAssertEqual(stubClient.currentSessionToken, "testSessionToken")
        XCTAssertTrue(stubClient.isUserLoggedIn)
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
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
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
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
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
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
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
            default: break
            }
        }
    }
    
    func testFetchFolderSucceed() {
        
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.fetchFolders() { result in
            if let content = try? result.get() {
                XCTAssertNotNil(content.children, "Folder without any children")
                guard let firstArticle = content.children.first else { return }
                
                XCTAssertEqual(firstArticle.id, "5f86baece0187e26a841def5")
            }
        }
    }
    
    func testFetchArticleContentSucceed() {
        
        let articleId = "testArticleId"
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customSuccessEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        let baseUrl = Client.config.baseServer.baseUrl.absoluteString
        stubClient.fetchArticle(articleId: articleId) { (result, isFullArticle) in
            if let content = try? result.get() {
                XCTAssertEqual(content.id, "5f86bcabe0187ed43f41dfa7")
                
                if let firstImage = content.images.first {
                    XCTAssertEqual(firstImage.mainImageURL, baseUrl+firstImage.uri)
                }
                XCTAssertNotNil(content.fitReadingData)
                XCTAssertNotNil(content.pdfData)
            }
            XCTAssertTrue(isFullArticle)
        }
    }
    
    func testFetchArticleContentFailedWithNoPermission() {
        
        let articleId = "testArticleId"
        guard let url = Bundle.current.url(forResource: "previewArticleContent", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return }
    
        let customFailedEndpointClosure = { (target: CoreAPIService) -> Endpoint in
            return Endpoint(url: URL(target: target).absoluteString,
                            sampleResponseClosure: { .networkResponse(403, data) },
                            method: target.method,
                            task: target.task,
                            httpHeaderFields: target.headers)
        }
        stubbingProvider = MoyaProvider<CoreAPIService>(endpointClosure: customFailedEndpointClosure, stubClosure: MoyaProvider.immediatelyStub)
        stubClient = Client(apiKey: appKey, appId: appId, networkProvider: stubbingProvider)
        
        stubClient.fetchArticle(articleId: articleId) { (result, isFullArticle) in
            if let content = try? result.get() {
                XCTAssertEqual(content.id, "5f86bcabe0187ed43f41dfa7")
                //XCTAssertNil(content.fitReadingData)
                //XCTAssertNil(content.pdfData)
            }
            XCTAssertFalse(isFullArticle)
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
