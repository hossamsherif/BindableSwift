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

protocol Onable: class {
    @discardableResult
    func on<O: UIControl>(selector:Selector, _ control:O, for event: UIControl.Event, _ disposableBag: DisposableBag?) -> Disposable
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
    
    @objc public func signal() { action() }
}

extension ImmutableEvent: Onable, Signallable, CallableAsFunction, CallableAsFunctionEvent { }




