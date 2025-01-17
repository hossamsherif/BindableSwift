//
//  UnsignedNumberTF.swift
//  BindableSwift_Example
//
//  Created by Hossam Sherif on 12/26/20.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import BindableSwift


class UnsignedNumberTF: UITextField {
    private lazy var validator = ImmutableEvent { [weak self]  in
        guard let self = self else { return }
        self.text = self.text?.filter { $0.isNumber }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    func commonInit() {
        validator.on(self, for: [Event.valueChanged, .editingChanged])
    }
}
