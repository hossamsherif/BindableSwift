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
    
    func testDisposableUnitDispose() {
        let bindable = Bindable(0)
        XCTAssertTrue(sut.container.isEmpty)
        let disposable = bindable.observe(disposableBag: sut) {_ in }
        XCTAssertEqual(sut.container.count, 1)
        disposable.dispose()
        XCTAssertTrue(sut.container.isEmpty)
    }

}
