//
//  Event.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation

public typealias Eventable<EventStateType> = EventBindable<EventStateType>
public typealias ImmutableEventable<EventStateType> = ImmutableEventBindable<EventStateType>

@propertyWrapper
public class Event {
    
    public typealias Immutable = ImmutableEvent
    public typealias ActionType = Immutable.ActionType
    
    public private(set) var immutable: Immutable
    
    public var action: ActionType {
        get {
            return immutable.action
        }
        set {
            immutable.action = newValue
        }
    }
    
    public var wrappedValue: Immutable {
        return immutable
    }
    
    public var projectedValue: ActionType {
        get {
            return immutable.action
        }
        set {
            immutable.action = newValue
        }
    }
    
    public init(_ action: @escaping ActionType = {}) {
        self.immutable = Immutable(action)
    }
}

public class ImmutableEvent {
    
    public typealias ActionType = () -> Void
    
    private var immutableBase: ImmutableEventBase<(), ActionType>
    
    public var action: ActionType {
        get {
            return immutableBase.action
        }
        set {
            immutableBase.action = newValue
        }
    }
    
    public init(_ action: @escaping ActionType = {}) {
        immutableBase = ImmutableEventBase<(),ActionType>(action)
    }
    
    public func on<O: UIControl>(_ control:O, event: UIControl.Event) {
        immutableBase.on(control, event: event)
    }
    
    /// valueChanged call back when UIControl value is changed
    /// - Parameter sender: changed UIControl object
    @objc fileprivate func valueChanged(sender: UIControl, event: UIControl.Event) {
        signal()
    }
    
    public func callAsFunction() {
        signal()
    }
    
    public func signal() {
        immutableBase.action()
    }
}



@propertyWrapper
public class EventBindable<EventStateType> {
    
    public typealias Immutable = ImmutableEventable<EventStateType>
    public typealias ActionType = Immutable.ActionType
    
    public private(set) var immutable: Immutable
    
    public var action: ActionType {
        get {
            return immutable.action
        }
        set {
            immutable.action = newValue
        }
    }
    
    public var wrappedValue: Immutable {
        return immutable
    }
    
    public var projectedValue: ActionType {
        get {
            return immutable.action
        }
        set {
            immutable.action = newValue
        }
    }
    
    public init(_ action: @escaping ActionType = {_ in}, _ eventStateValue: EventStateType? = nil) {
        self.immutable = Immutable(action, eventStateValue)
    }
}

public class ImmutableEventBindable<EventStateType> : ImmutableEventBase<EventStateType,((EventStateType) -> Void) -> Void> {
    
    public typealias ActionType = ((EventStateType) -> Void) -> Void
    public typealias CompletionType<EventStateType> = (EventStateType) -> Void
    
    public func callAsFunction() -> Bindable<EventStateType>.Immutable {
        return signal()
    }
    
    override init(_ action: @escaping ActionType = {_ in}, _ eventStateValue: EventStateType? = nil) {
        super.init(action, eventStateValue)
    }
    
    @discardableResult
    public override func signal() -> Bindable<EventStateType>.Immutable {
        action { [weak self] eventState in
            self?.bindable.value = eventState
        }
        return asBindable
    }
}

public class ImmutableEventBase<EventStateType, ActionType> {
    
    lazy fileprivate var primaryKey: ObjectIdentifier = ObjectIdentifier(self)
    
    fileprivate var bindable: Bindable<EventStateType>
    
    fileprivate var action: ActionType
    
    public var asBindable: Bindable<EventStateType>.Immutable {
        return bindable.immutable
    }
    
    public init(_ action: ActionType, _ eventStateValue: EventStateType? = nil) {
        self.action = action
        bindable = Bindable(eventStateValue)
        if let eventStateValue = eventStateValue {
            bindable.value = eventStateValue
        }
    }
    
    deinit {
        DisposableBag.dispose(self)
    }
    
    @discardableResult
    public func on<O: UIControl>(_ control:O, event: UIControl.Event) -> Self {
        control.addTarget(self, action: #selector(valueChanged(sender:event:)), for: event)
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(control)))\(event)"
        let disposableEvent = DisposableUnit(primaryKey, secondaryKey) { [weak self, weak control] in
            guard let self = self, let control = control else { return }
            control.removeTarget(self, action:  #selector(self.valueChanged(sender:event:)), for: event)
         }
        DisposableBag.container(self, [disposableEvent])
        return self
    }
    
    
    
    @discardableResult
    public func observe(_ complection:@escaping (EventStateType) -> ()) -> Disposable {
        return bindable.observe(complection)
    }
    
    /// valueChanged call back when UIControl value is changed
    /// - Parameter sender: changed UIControl object
    @objc fileprivate func valueChanged(sender: UIControl, event: UIControl.Event) {
        signal()
    }
    
    @discardableResult
    public func signal() -> Bindable<EventStateType>.Immutable {
        //*** Note this function should be overriden from any subclass to call action ***
        return bindable.immutable
    }
}

