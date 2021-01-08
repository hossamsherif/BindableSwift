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
    
    func testInitWithAction() {
        var i = 0
        let testValue = 1
        _sut = Event({
            i = testValue
        })
        sut()
        XCTAssertEqual(i, testValue)
    }
    
    func testInitDefault() {
        var i = 0
        let testValue = 1
        _sut = Event()
        $sut = { i = testValue }
        sut.signal()
        XCTAssertEqual(i, testValue)
    }
    
    func testProjectedValueSet() {
        var i = 0
        let testValue = 1
        $sut = { i = testValue }
        _sut.action()
        XCTAssertEqual(i, testValue)
    }
    
    func testProjectedValueGet() {
        var i = 0
        let testValue = 1
        $sut = { i = testValue }
        $sut()
        XCTAssertEqual(i, testValue)
    }
    
    func testCallableAsFuntion() {
        var i = 0
        let testValue = 1
        $sut = { i = testValue }
        sut() //Call as function
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
    
    func testOnGesture() {
        let exp = expectation(description: "testOnGesture")
        let tapGesture = UITapGestureRecognizer()
        let target = UIView()
        var tapActionCalled = false
        $sut = {
            tapActionCalled = true
            exp.fulfill()
        }
        sut.on(tapGesture, on: target)
        tapGesture.state = .ended
        waitForExpectations(timeout: 0.1) { (error) in
            XCTAssertNil(error)
            XCTAssertTrue(tapActionCalled)
        }
    }
    
    func testOnGestureDispose() {
        let tapGesture = UITapGestureRecognizer()
        let target = UIView()
        var tapActionCalled = false
        $sut = { tapActionCalled = true }
        let disposeable = sut.on(tapGesture, on: target)
        disposeable.dispose()
        XCTAssertEqual(target.gestureRecognizers?.isEmpty, true)
        XCTAssertFalse(tapActionCalled)
    }

    
    func onEventGesture( _ eventGesture: EventGesture, on view: UIView) {
        let exp = expectation(description: "onEventGesture\(eventGesture)")
        var eventActionCalled = false
        $sut = {
            eventActionCalled = true
            exp.fulfill()
        }
        XCTAssertEqual((view.gestureRecognizers?.count ?? 0),  0)
        sut.on(eventGesture, on: view)
        //Assert view UserInteractionEnabled and has gestureRecognizer added
        XCTAssertTrue(view.isUserInteractionEnabled)
        XCTAssertEqual((view.gestureRecognizers?.count ?? 0),  1)
        //Simulate gesture state ended to fire
        view.gestureRecognizers?.first?.state = .ended
        //Wait for expectations fulfillment
        waitForExpectations(timeout: 0.1) { (error) in
            XCTAssertNil(error)
            XCTAssertTrue(eventActionCalled)
        }
    }
    
    func testOnEventGestureTap() {
        onEventGesture(.tap, on: UIView())
    }
    
    func testOnEventGesturePinch() {
        onEventGesture(.pinch, on: UIView())
    }
    
    func testOnEventGestureRotaion() {
        onEventGesture(.rotaion, on: UIView())
    }
    func testOnEventGestureSwipe() {
        onEventGesture(.swipe, on: UIView())
    }
    func testOnEventGesturePan() {
        onEventGesture(.pan, on: UIView())
    }
    func testOnEventGestureScreenEdgePan() {
        onEventGesture(.screenEdgePan, on: UIView())
    }
    func testOnEventGestureLongPress() {
        onEventGesture(.longPress, on: UIView())
    }
    func testOnEventGestureCustom() {
        onEventGesture(.custom(gesture: UITapGestureRecognizer()), on: UIView())
    }
}
