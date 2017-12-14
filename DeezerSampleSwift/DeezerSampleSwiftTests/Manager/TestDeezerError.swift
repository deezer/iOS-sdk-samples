//
//  TestDeezerError.swift
//  DeezerSampleSwiftTests
//
//  Created by Steven Martreux on 10/11/2017.
//  Copyright © 2017 Steven Martreux. All rights reserved.
//

import XCTest

class TestDeezerError: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testErrorDataNotFound() {
        let error = NSError.instance(type: .dataNotFound, userInfo: nil)
        XCTAssert(error.type == .dataNotFound)
        XCTAssert(error.code == DeezerErrorType.dataNotFound.rawValue)
        XCTAssert(error.type.description == DeezerErrorType.dataNotFound.description)
        XCTAssert(error.domain == domainDeezerSDK)
    }
    
    func testErrorCode() {
        let error = NSError(domain: domainDeezerSDK, code: 200, userInfo: nil)
        XCTAssert(error.type == .permission)
        XCTAssert(error.code == DeezerErrorType.permission.rawValue)
        XCTAssert(error.type.description == DeezerErrorType.permission.description)
        XCTAssert(error.domain == domainDeezerSDK)
    }
    
}
