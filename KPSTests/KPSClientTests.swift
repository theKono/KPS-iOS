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
        //stubClient = Client(apiKey: "API_KEY", appId: "5f86b8c8af7cc10a7d5a142f", networkProvider: stubbingProvider)
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
    
    func customSuccessEndpointClosure(_ target: CoreAPIService) -> Endpoint {
        return Endpoint(url: URL(target: target).absoluteString,
                        sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                        method: target.method,
                        task: target.task,
                        httpHeaderFields: target.headers)
    }
    
}
