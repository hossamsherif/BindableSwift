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

}


class EventableProvider<T> {
    @Eventable<T> var sut
    
    init() { }
    
    init(_ value: T) { _sut = Eventable(value: value) }
}
