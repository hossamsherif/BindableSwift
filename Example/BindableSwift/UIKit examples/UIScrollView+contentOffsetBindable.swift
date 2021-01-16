//
//  CustomScrollView.swift
//  BindableSwift_Example
//
//  Created by Hossam Sherif on 12/26/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import BindableSwift


public extension UIScrollView {
    private struct Holder {
        static let bindable = ObjectAssociation<Bindable<CGPoint>>()
        static let kvo = ObjectAssociation<NSKeyValueObservation>()
    }
    var contentOffsetBindable: Bindable<CGPoint>.Immutable {
        Holder.bindable[self]?.immutable ?? {
            let bindable = Bindable<CGPoint>()
            Holder.kvo[self] = observe(\.contentOffset, options: .new) { [weak bindable] (_, change) in
                guard let newValue = change.newValue else { return }
                bindable?.update(newValue)
            }
            Holder.bindable[self] = bindable
            return bindable.immutable
        }()
    }
}
