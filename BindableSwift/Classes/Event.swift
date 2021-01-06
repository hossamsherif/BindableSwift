//
//  Event.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation

public protocol Signallable {
    associatedtype ReturnType
    ///Send signal to receiver
    func signal() -> ReturnType
}

public protocol CallableAsFunction {
    associatedtype ReturnType
    ///Call on instance directly
    @discardableResult
    func callAsFunction() -> ReturnType
}
public enum EventGesture {
    
    case tap, pinch, rotaion, swipe, pan, screenEdgePan, longPress, custom(gesture: UIGestureRecognizer)
    
    func callAsFunction() -> UIGestureRecognizer {
        switch self {
        case .tap: return UITapGestureRecognizer()
        case .pinch: return UIPinchGestureRecognizer()
        case .rotaion: return UIRotationGestureRecognizer()
        case .swipe: return UISwipeGestureRecognizer()
        case .pan: return UIPanGestureRecognizer()
        case .screenEdgePan: return UIScreenEdgePanGestureRecognizer()
        case .longPress: return UILongPressGestureRecognizer()
        case .custom(let gesture): return gesture
        }
    }
}
protocol Onable: class {
    @discardableResult
    func on<O: UIControl>(selector:Selector, _ control:O, for event: UIControl.Event, _ disposableBag: DisposableBag?) -> Disposable
    @discardableResult
    func on<G: UIGestureRecognizer>(selector:Selector, _ gesture:G, on view: UIView?, _ disposableBag: DisposableBag?) -> Disposable
    @discardableResult
    func on(selector:Selector, _ eventGesture: EventGesture, on view: UIView?, _ disposableBag: DisposableBag?) -> Disposable 
}
extension Onable {
    @discardableResult
    func on<O: UIControl>(selector:Selector, _ control:O, for event: UIControl.Event, _ disposableBag: DisposableBag? = nil) -> Disposable {
        control.addTarget(self, action: selector, for: event)
        let primaryKey: ObjectIdentifier = ObjectIdentifier(self)
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(control)))\(event)"
        return DisposableUnit(primaryKey, secondaryKey, disposableBag: disposableBag) { [weak self, weak control] in
            guard let self = self, let control = control else { return }
            control.removeTarget(self, action:  selector, for: event)
        }
    }
    
    @discardableResult
    func on<G: UIGestureRecognizer>(selector:Selector, _ gesture:G, on view: UIView? = nil, _ disposableBag: DisposableBag? = nil) -> Disposable {
        return on(selector: selector, .custom(gesture: gesture), on: view, disposableBag)
    }
    
    @discardableResult
    func on(selector:Selector, _ eventGesture: EventGesture, on view: UIView? = nil, _ disposableBag: DisposableBag? = nil) -> Disposable {
        let gesture = eventGesture()
        if let view = view {
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(gesture)
        }
        gesture.addTarget(self, action: selector)
        let primaryKey: ObjectIdentifier = ObjectIdentifier(self)
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(gesture)))"
        return DisposableUnit(primaryKey, secondaryKey, disposableBag: disposableBag) { [weak self, weak gesture, weak view] in
            guard let self = self, let gesture = gesture, let view = view else { return }
            gesture.removeTarget(self, action:  selector)
            view.removeGestureRecognizer(gesture)
        }
    }
}


public protocol CallableAsFunctionEvent: Signallable, CallableAsFunction { }

extension CallableAsFunctionEvent {
    @discardableResult
    public func callAsFunction() -> ReturnType {
        return signal()
    }
}


/// Event type and propertyWarraper over ImmutableEvent.
@propertyWrapper
public class Event {
    
    public typealias Immutable = ImmutableEvent
    public typealias ActionType = Immutable.ActionType
    
    /// ImmutableEvent  wrapped by this wrapper
    public private(set) var immutable: Immutable
    
    /// ImmutableEvent's ActionType projected by this wrapper
    public var action: ActionType {
        get { return immutable.action }
        set { immutable.action = newValue }
    }
    
    public var wrappedValue: Immutable { return immutable }
    
    public var projectedValue: ActionType {
        get { return immutable.action }
        set { immutable.action = newValue }
    }
    
    /// Main int for Event property wrapper
    /// - Parameter action: Action block value of type ActionType  for ImmutableEvent - default to empty block
    public init(_ action: @escaping ActionType = {}) {
        self.immutable = Immutable(action)
    }
}

/// ImmutableEvent type  with no binding value.
/// Can be:
/// -  signalled
/// -  Add on event with an action block
/// - calledAsFunction
public class ImmutableEvent {
    
    public typealias ActionType = () -> Void
    
    fileprivate var action: ActionType
    
    /// Main int for ImmutableEvent
    /// - Parameter action: Action block value of type ActionType - default to empty block
    public init(_ action: @escaping ActionType = {}) { self.action = action }
    
    deinit { DisposableBag.dispose(self) }
    
    @discardableResult
    public func on<O: UIControl>(_ control:O, for event: UIControl.Event, _ disposableBag: DisposableBag? = nil) -> Disposable {
        return on(selector: #selector(self.signal), control, for: event, disposableBag)
    }
    
    @discardableResult
    public func on<G: UIGestureRecognizer, V: UIView>(_ gesture:G, on view: V? = nil, _ disposableBag: DisposableBag? = nil) -> Disposable {
        return on(selector: #selector(self.signal), gesture, on: view, disposableBag)
    }
    
    @discardableResult
    public func on<V: UIView>(_ eventGesture: EventGesture, on view: V? = nil, _ disposableBag: DisposableBag? = nil) -> Disposable {
        return on(selector: #selector(self.signal), eventGesture, on: view, disposableBag)
    }
    
    @objc public func signal() { action() }
}

extension ImmutableEvent: Onable, Signallable, CallableAsFunction, CallableAsFunctionEvent { }




