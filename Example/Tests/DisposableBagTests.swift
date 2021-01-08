//
//  DisposableBagTests.swift
//  BindableSwift_Tests
//
//  Created by Hossam Sherif on 1/1/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
@testable import BindableSwift

class DisposableBagTests: XCTestCase {
    
    var sut: DisposableBag!

    
    override func setUpWithError() throws {
        sut = DisposableBag()
    }

    override func tearDownWithError() throws {
        sut = nil
    }
    
    func testDisposePrimaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        sut.dispose(primaryKey: primaryKey)
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
        sut.dispose(self)
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
        sut.dispose(secondaryKey: secondaryKey)
        XCTAssertTrue(disposableMock.isDisposed)
    }
    
    func testGetWithPrimaryKeySecondaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        let resultDisposableUnit = sut.get(primaryKey, secondaryKey)
        XCTAssertTrue(disposableMock === resultDisposableUnit)
    }
    
    func testGetWithPrimaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        let resultDisposableUnit = sut.get(primaryKey: primaryKey)
        XCTAssertEqual(resultDisposableUnit?.count ?? 0, 1)
        XCTAssertTrue(disposableMock === resultDisposableUnit?.first?.value)
    }
    
    func testGetWithSecondaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        let resultDisposableUnit = sut.get(secondaryKey: secondaryKey)
        XCTAssertEqual(resultDisposableUnit?.count ?? 0, 1)
        XCTAssertTrue(disposableMock === resultDisposableUnit?.first?.value)
    }
    
    func testSetWithPrimaryKeySecondaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let disposableMock = DisposableMock()
        sut.set(primaryKey, secondaryKey, value: disposableMock)
        XCTAssertEqual(sut.container.count, 1)
        let resultDisposableUnit = sut.get(secondaryKey: secondaryKey)
        XCTAssertEqual(resultDisposableUnit?.count ?? 0, 1)
        XCTAssertTrue(disposableMock === resultDisposableUnit?.first?.value)
    }
    
    func testRemovePrimaryKeySecondaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let disposableMock = DisposableMock()
        sut.set(primaryKey, secondaryKey, value: disposableMock)
        XCTAssertEqual(sut.container.count, 1)
        sut.remove(primaryKey, secondaryKey)
        XCTAssertTrue(sut.container.isEmpty)
    }
    
    func testRemovePrimaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let disposableMock = DisposableMock()
        sut.set(primaryKey, secondaryKey, value: disposableMock)
        XCTAssertEqual(sut.container.count, 1)
        sut.remove(primaryKey: primaryKey)
        XCTAssertTrue(sut.container.isEmpty)
    }
    
    func testRemoveSecondaryKey() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let disposableMock = DisposableMock()
        sut.set(primaryKey, secondaryKey, value: disposableMock)
        XCTAssertEqual(sut.container.count, 1)
        sut.remove(secondaryKey: secondaryKey)
        XCTAssertTrue(sut.container.isEmpty)
    }
    
    func testRemoveKeyPair() {
        XCTAssertTrue(sut.container.isEmpty)
        let primaryKey = ObjectIdentifier(self)
        let secondaryKey = UUID().uuidString
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        let disposableMock = DisposableMock()
        sut.container[keyPair] = disposableMock
        XCTAssertEqual(sut.container.count, 1)
        sut.remove(keyPair: keyPair)
        XCTAssertTrue(sut.container.isEmpty)
    }
    
    
}

class DisposableMock: Disposable {
    var isDisposed = false
    func dispose() { isDisposed = true }
}
