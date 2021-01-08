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
    
    @Eventable<Bool> var sut
    
    override func setUpWithError() throws {
        _sut = Eventable<Bool>()
    }
    
    override func tearDownWithError() throws {
        DisposableBag.shared.container.removeAll()
    }
    
    func testCallableAsFunction() {
        var target = false
        let testValue = true
        $sut = { $0(testValue) }
        sut.observe { target = $0 }
        sut()
        XCTAssertEqual(target, testValue)
    }

    func testSignallable() {
        var target = false
        let testValue = true
        $sut = { $0(testValue) }
        sut.observe { target = $0 }
        sut.signal()
        XCTAssertEqual(target, testValue)
    }
    
    func testEventableProjectedValueSet() {
        var target = false
        let testValue = true
        $sut = { $0(testValue) }
        sut.observe { target = $0 }
        sut.signal()
        XCTAssertEqual(target, testValue)
    }
    
    func testEventableProjectedValueGet() {
        var target = false
        let testValue = true
        $sut = { $0(testValue) }
        $sut { target = $0 }
        XCTAssertEqual(target, testValue)
    }
    
    func testEventableDeinit() {
        XCTAssertTrue(DisposableBag.shared.container.isEmpty)
        var provider: EventableProvider<Bool>? = EventableProvider<Bool>()
        var target = false
        let testValue = true
        provider?.$sut = { $0(testValue) }
        provider?.sut.observe { target = $0 }
        provider?.sut.signal()
        XCTAssertEqual(DisposableBag.shared.container.count, 1)
        XCTAssertEqual(target, testValue)
        provider = nil
        XCTAssertTrue(DisposableBag.shared.container.isEmpty)

    }
    
    func testOnableWithButton() {
        let target = UIButton()
        var triggered = false
        let testValue = true
        $sut = { $0(testValue) }
        sut.observe{ triggered = $0 }
        sut.on(target, for: .touchUpInside)
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
        let exp = expectation(description: "testOnGesture")
        let tapGesture = UITapGestureRecognizer()
        let target = UIView()
        $sut = { stateHander in
            stateHander(true)
            exp.fulfill()
        }
        sut.on(tapGesture, on: target)
        tapGesture.state = .ended
        waitForExpectations(timeout: 0.1) { [weak self] (error) in
            guard let self = self else { return }
            XCTAssertNil(error)
            XCTAssertTrue(self.sut.asBindable.value!)
        }
    }
    
    func onEventGesture( _ eventGesture: EventGesture, on view: UIView) {
        let exp = expectation(description: "onEventGesture\(eventGesture)")
        $sut = { stateHander in
            stateHander(true)
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
        waitForExpectations(timeout: 0.1) { [weak self] (error) in
            guard let self = self else { return }
            XCTAssertNil(error)
            XCTAssertTrue(self.sut.asBindable.value!)
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
