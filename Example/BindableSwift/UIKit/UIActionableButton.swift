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

class UIActionableButton: UIButton {
    
    private var action: ((UIButton)->())?
    private(set) lazy var actionEvent = ImmutableEventable(self) { [weak self] sender in
        guard let self = self else { return }
        self.action?(self)
        sender(self)
    }
    
    convenience init(frame: CGRect = .zero, action:((UIButton)->())? = nil) {
        self.init(frame: frame)
        self.action = action
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        actionEvent.on(self, for: Event.touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addAction(_ action: ((UIButton) -> ())?) {
        self.action = action
    }
}
