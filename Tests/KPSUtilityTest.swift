//
//  KPSUtilityTest.swift
//  KPSTests
//

import XCTest
@testable import KPS

class KPSUtilityTest: XCTestCase {

    var utility: KPSUtiltiy!

    override func setUp() {
        utility = KPSUtiltiy()
    }

    func testAdd() {
        XCTAssertEqual(utility.add(a: 1, b: 1), 2)
    }

    func testSub() {
        XCTAssertEqual(utility.sub(a: 1, b: 1), 0)
    }
}
