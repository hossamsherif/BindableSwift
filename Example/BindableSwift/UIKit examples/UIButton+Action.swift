//
//  UIActionableButton.swift
//  BindableSwift_Example
//
//  Created by Hossam Sherif on 12/26/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import BindableSwift
import UIKit

typealias BSEvent = BindableSwift.Event
typealias ActionBlocks = [String: ((UIButton?) -> ())?]

extension UIButton {
    
    private struct Holder {
        static let actionEvent = ObjectAssociation<BSEvent>()
        static let disposableBag = ObjectAssociation<DisposableBag>()
        static let actionBlocks = ObjectAssociation<ActionBlocks>()
    }
    
    private var disposableBag: DisposableBag {
        Holder.disposableBag[self] ?? {
            let disposableBag = DisposableBag()
            Holder.disposableBag[self] = disposableBag
            return disposableBag
        }()
    }
    private var actionBlocks: ActionBlocks {
        get {
            Holder.actionBlocks[self] ?? {
                let actionBlocks = ActionBlocks()
                Holder.actionBlocks[self] = actionBlocks
                return actionBlocks
            }()
        }
        set { Holder.actionBlocks[self] = newValue }
    }
    private var actionEvent: BSEvent? {
        Holder.actionEvent[self] ?? {
            let actionEvent = BSEvent { [weak self] in
                self?.actionBlocks.forEach{ $0.value?(self) }
            }
            actionEvent.immutable.on(self, for: Event.touchUpInside, disposableBag)
            Holder.actionEvent[self] = actionEvent
            return actionEvent
        }()
    }
    @discardableResult
    func addAction(_ action: ((UIButton?) -> ())?) -> Disposable? {
        guard let _ = actionEvent else { return nil }
        let key = UUID().uuidString
        actionBlocks[key] = action
        return DisposableUnit(self, key, disposableBag: disposableBag) { [weak self] in
            self?.actionBlocks.removeValue(forKey: key)
        }
        
    }
}
