//
//  DisposableUnitTests.swift
//  BindableSwift_Tests
//
//  Created by Hossam Sherif on 1/8/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import BindableSwift

class DisposableUnitTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitPrimaryKeySecondaryKey() {
        let disposableBag = DisposableBag()
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        var disposeBlockCalled = false
        XCTAssertTrue(disposableBag.container.isEmpty)
        let disposableUnit = DisposableUnit(primaryKey, secondaryKey, disposableBag: disposableBag) {
            disposeBlockCalled = true
        }
        XCTAssertFalse(disposableUnit.isDisposed)
        XCTAssertEqual(disposableUnit.keyPair.primary, primaryKey)
        XCTAssertEqual(disposableUnit.keyPair.secondary, secondaryKey)
        XCTAssertTrue(disposableUnit.disposableBag === disposableBag)
        XCTAssertEqual(disposableBag.container.count, 1)
        disposableUnit.dispose()
        XCTAssertTrue(disposeBlockCalled)
    }


    func testInitKeyPair() {
        let disposableBag = DisposableBag()
        let keyPair = KeyPair(primary: ObjectIdentifier(self), secondary: UUID().uuidString)
        var disposeBlockCalled = false
        XCTAssertTrue(disposableBag.container.isEmpty)
        let disposableUnit = DisposableUnit(keyPair, disposableBag: disposableBag) {
            disposeBlockCalled = true
        }
        XCTAssertFalse(disposableUnit.isDisposed)
        XCTAssertEqual(disposableUnit.keyPair, keyPair)
        XCTAssertTrue(disposableUnit.disposableBag === disposableBag)
        XCTAssertEqual(disposableBag.container.count, 1)
        disposableUnit.dispose()
        XCTAssertTrue(disposeBlockCalled)
    }
    
    func testDispose() {
        let disposableBag = DisposableBag()
        let keyPair = KeyPair(primary: ObjectIdentifier(self), secondary: UUID().uuidString)
        var disposeBlockCalled = false
        XCTAssertTrue(disposableBag.container.isEmpty)
        let disposableUnit = DisposableUnit(keyPair, disposableBag: disposableBag) {
            disposeBlockCalled = true
        }
        XCTAssertFalse(disposableUnit.isDisposed)
        XCTAssertEqual(disposableBag.container.count, 1)
        disposableUnit.dispose()
        XCTAssertTrue(disposableUnit.isDisposed)
        XCTAssertTrue(disposeBlockCalled)
        XCTAssertTrue(disposableBag.container.isEmpty)
    }
    
    func testDisposeTwice() {
        let disposableBag = DisposableBag()
        let keyPair = KeyPair(primary: ObjectIdentifier(self), secondary: UUID().uuidString)
        var disposeBlockCalledCount = 0
        XCTAssertTrue(disposableBag.container.isEmpty)
        let disposableUnit = DisposableUnit(keyPair, disposableBag: disposableBag) {
            disposeBlockCalledCount += 1
        }
        XCTAssertFalse(disposableUnit.isDisposed)
        XCTAssertEqual(disposableBag.container.count, 1)
        disposableUnit.dispose()
        XCTAssertTrue(disposableUnit.isDisposed)
        XCTAssertEqual(disposeBlockCalledCount, 1)
        disposableUnit.dispose()
        XCTAssertEqual(disposeBlockCalledCount, 1)
        XCTAssertTrue(disposableBag.container.isEmpty)
    }

}
