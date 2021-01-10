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


public final class ObjectAssociation<T: AnyObject> {

    private let policy: objc_AssociationPolicy

    /// - Parameter policy: An association policy that will be used when linking objects.
    public init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }

    /// Accesses associated object.
    /// - Parameter index: An object whose associated object is to be accessed.
    public subscript(index: AnyObject) -> T? {
        get { return objc_getAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque()) as! T? }
        set { objc_setAssociatedObject(index, Unmanaged.passUnretained(self).toOpaque(), newValue, policy) }
    }
}

public extension UIScrollView {
    private struct Holder {
        static let bindable = ObjectAssociation<Bindable<CGPoint>>()
        static let kvo = ObjectAssociation<NSKeyValueObservation>()
    }
    var contentOffsetBindable:Bindable<CGPoint>.Immutable {
        guard let bindable = Holder.bindable[self] else {
            let bindable = Bindable<CGPoint>()
            Holder.kvo[self] = observe(\.contentOffset, options: .new) { [weak bindable] (_, change) in
                guard let newValue = change.newValue else { return }
                bindable?.update(newValue)
            }
            Holder.bindable[self] = bindable
            return bindable.immutable
        }
        return  bindable.immutable
    }
}


class BSScrollView: UIScrollView {
    weak var delegateProxy:UIScrollViewDelegate?
    var didScrollAction: ((CGPoint) -> ())?
    private(set) var didScrollEvent: ImmutableEventable<CGPoint>!
    
    convenience init(frame: CGRect = .zero, _ didScrollAction: @escaping (CGPoint) -> ()) {
        self.init(frame: frame)
        self.didScrollAction = didScrollAction
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
        didScrollEvent = ImmutableEventable(CGPoint.zero) { [weak self] stateHandler in
            guard let self = self else { return }
            self.didScrollAction?(self.contentOffset)
            stateHandler(self.contentOffset)
        }
        self.delegate = self
    }
    
    func addDidScrollAction(_ action: ((CGPoint) -> ())?) {
        self.didScrollAction = action
    }
}

extension BSScrollView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollEvent()
        delegateProxy?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewDidZoom?(scrollView)
    }

    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewWillBeginDragging?(scrollView)
    }


    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegateProxy?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegateProxy?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewWillBeginDecelerating?(scrollView)
    }

    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewDidEndDecelerating?(scrollView)
    }

    
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return delegateProxy?.viewForZooming?(in: scrollView)
    }

    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        delegateProxy?.scrollViewWillBeginZooming?(scrollView, with: view)
    }

    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        delegateProxy?.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale)
    }

    
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return delegateProxy?.scrollViewShouldScrollToTop?(scrollView) ?? true
    }

    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewDidScrollToTop?(scrollView)
    }

    
    
    
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        delegateProxy?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
