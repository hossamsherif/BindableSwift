//
//  DisposableBagSharedTests.swift
//  BindableSwift_Tests
//
//  Created by Hossam Sherif on 1/8/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import BindableSwift

class DisposableBagSharedTests: XCTestCase {
    
    var sut: DisposableBag!

    
    override func setUpWithError() throws {
        sut = DisposableBag.shared
    }

    override func tearDownWithError() throws {
        sut.container.removeAll()
    }
    
    
    func testDisposePrimaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        DisposableBag.dispose(primaryKey: primaryKey)
        XCTAssertTrue(disposableMock.isDisposed)
    }
    
    func testDisposeRefrenceObject() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        DisposableBag.dispose(self)
        XCTAssertTrue(disposableMock.isDisposed)
    }
    
    func testDisposeSecondaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        DisposableBag.dispose(secondaryKey: secondaryKey)
        XCTAssertTrue(disposableMock.isDisposed)
    }
    



}
