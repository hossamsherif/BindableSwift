//
//  EventTests.swift
//  BindableSwift_Tests
//
//  Created by Hossam Sherif on 12/31/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import BindableSwift


class EventTests: XCTestCase {
    
    @Event var sut

    override func setUpWithError() throws {
        _sut = Event()
    }

    override func tearDownWithError() throws {
        DisposableBag.dispose(sut)
    }
    
    
    func testCallableAsFuntion() {
        var i = 0
        let testValue = 1
        $sut = { i = testValue }
        //Call as function
        sut()
        XCTAssertEqual(i, testValue)
    }
    
    func testSignable() {
        var i = 0
        let testValue = 1
        $sut = { i = testValue }
        //Call as function
        sut.signal()
        XCTAssertEqual(i, testValue)
    }
    
    func testOnableWithButton() {
        let target = UIButton()
        var triggered = false
        let testValue = true
        $sut = { triggered = testValue }
        sut.on(target, for: .touchUpInside)
        target.sendActions(for: .touchUpInside)
        XCTAssertEqual(triggered, testValue)
    }
    
    func testOnableWithUITextField() {
        let target = UITextField()
        var capturedText:String?
        $sut = { capturedText = target.text }
        sut.on(target, for: [.editingChanged, .valueChanged])
        let testValue = "new text"
        target.text = testValue
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(capturedText, testValue)
    }

}
