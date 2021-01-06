//
//  EventableTests.swift
//  BindableSwift_Tests
//
//  Created by Hossam Sherif on 12/31/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import XCTest
@testable import BindableSwift

class EventableTests: XCTestCase {
    
    func testCallableAsFunction() {
        let provider = EventableProvider<Bool>()
        var target = false
        let testValue = true
        provider.$sut = { $0(testValue) }
        provider.sut.observe { target = $0 }
        provider.sut()
        XCTAssertEqual(target, testValue)
    }

    func testSignallable() {
        let provider = EventableProvider<Bool>()
        var target = false
        let testValue = true
        provider.$sut = { $0(testValue) }
        provider.sut.observe { target = $0 }
        provider.sut.signal()
        XCTAssertEqual(target, testValue)
    }
    
    func testOnableWithButton() {
        let provider = EventableProvider<Bool>()
        let target = UIButton()
        var triggered = false
        let testValue = true
        provider.$sut = { $0(testValue) }
        provider.sut.observe{ triggered = $0 }
        provider.sut.on(target, for: .touchUpInside)
        target.sendActions(for: .touchUpInside)
        XCTAssertEqual(triggered, testValue)
    }
    
    func testOnableWithUITextField() {
        let provider = EventableProvider<String>()
        let target = UITextField()
        //Bind towWay with eventable EventState
        provider.sut.asBindable.bindOn(target, \.text).towWay.done()
        //Eventable action
        provider.$sut = { [weak provider] in $0(provider?.sut.asBindable.value?.capitalized ?? "") }
        //Eventable trigger on
        provider.sut.on(target, for: [.editingChanged, .valueChanged])
        //Change textField text
        let testValue = "new text"
        target.text = testValue
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(target.text, "New Text")
    }
    
    func testOnGesture() {
        let provider = EventableProvider(false)
        let exp = expectation(description: "testOnGesture")
        let tapGesture = UITapGestureRecognizer()
        let target = UIView()
        provider.$sut = { stateHander in
            stateHander(true)
            exp.fulfill()
        }
        provider.sut.on(tapGesture, on: target)
        tapGesture.state = .ended
        waitForExpectations(timeout: 0.1) { (error) in
            XCTAssertNil(error)
            XCTAssertTrue(provider.sut.asBindable.value!)
        }
    }
    
    func onEventGesture( _ eventGesture: EventGesture, on view: UIView) {
        let exp = expectation(description: "onEventGesture\(eventGesture)")
        let provider = EventableProvider(false)
        provider.$sut = { stateHander in
            stateHander(true)
            exp.fulfill()
        }
        XCTAssertEqual((view.gestureRecognizers?.count ?? 0),  0)
        provider.sut.on(eventGesture, on: view)
        //Assert view UserInteractionEnabled and has gestureRecognizer added
        XCTAssertTrue(view.isUserInteractionEnabled)
        XCTAssertEqual((view.gestureRecognizers?.count ?? 0),  1)
        //Simulate gesture state ended to fire
        view.gestureRecognizers?.first?.state = .ended
        //Wait for expectations fulfillment
        waitForExpectations(timeout: 0.1) { (error) in
            XCTAssertNil(error)
            XCTAssertTrue(provider.sut.asBindable.value!)
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


class EventableProvider<T> {
    @Eventable<T> var sut
    
    init() { }
    
    init(_ value: T) { _sut = Eventable(value: value) }
}
