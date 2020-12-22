//
//  Eventable.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/22/20.
//

import Foundation

public typealias Eventable<EventStateType> = EventBindable<EventStateType>
public typealias ImmutableEventable<EventStateType> = ImmutableEventBindable<EventStateType>
public typealias ImmutableEventableBase<EventStateType,ActionType> = ImmutableEventBindableBase<EventStateType,ActionType>

/// EventBindale type and propertyWarraper over ImmutableEventBindable
/// Take EventStateType indicating the type of bindable associtated with it
@propertyWrapper
public class EventBindable<EventStateType> {
    
    public typealias Immutable = ImmutableEventable<EventStateType>
    public typealias ActionType = Immutable.ActionType
    
    /// ImmutableEventable wrapped by this wrapper
    public private(set) var immutable: Immutable
    
    /// ImmutableEventable's ActionType projected by this wrapper
    public var action: ActionType {
        get { return immutable.action }
        set { immutable.action = newValue }
    }
    
    public var wrappedValue: Immutable { return immutable }
    
    public var projectedValue: ActionType {
        get { return immutable.action }
        set { immutable.action = newValue }
    }
    
    /// default Init for Eventable
    /// - Parameters:
    ///   - action: action block that should be called when signalled or `on(_:f,or:_)`'s event is fired
    ///   - eventStateValue: The associated value for the ImmutableEventable
    public init(_ action: @escaping ActionType = {_ in}, _ eventStateValue: EventStateType? = nil) {
        self.immutable = Immutable(action, eventStateValue)
    }
}
/// ImmutableEventBindable type with associated bindable of value of type EventStateType
/// Can be:
/// -  signalled which return the associated bindable
/// -  Add on event with an action block
/// - bind on Event state
/// - calledAsFunction to signal
public class ImmutableEventBindable<EventStateType> : ImmutableEventableBase<EventStateType,ImmutableEventBindable.ActionType> {
    
    public typealias ImmutableBindable = Bindable<EventStateType>.Immutable
    public typealias ActionType = ((EventStateType) -> Void) -> Void
    public typealias CompletionType<EventStateType> = (EventStateType) -> Void
    
    /// Default Init for ImmutableEventable
    /// - Parameters:
    ///   - action: action block that should be called when signalled or `on(_:f,or:_)`'s event is fired
    ///   - eventStateValue: The associated value for this ImmutableEvent's Bindable
    override init(_ action: @escaping ActionType = {_ in}, _ eventStateValue: EventStateType? = nil) {
        super.init(action, eventStateValue)
    }
    
    @discardableResult
    public override func signal() -> ImmutableBindable {
        action { [weak self] eventState in
            self?.bindable.value = eventState
        }
        return asBindable
    }
}

/// ImmutableEventBindableBase type with 2 assocated type:
/// 1- `EventStateType` is the `BindingType` for the associated bindable.
/// 2- `ActionType` is the action block type that should be called when signalled (either by `on(_,for:)` or by manually signal the event)
/// The base class for ImmutableEventBindable can be extended and build your own Eventable if needed.
/// Note in the sublclass of ImmutableEventableBase, it should override the signal function to call the action block
/// Can be:
/// -  signalled which return the associated bindable
/// -  Add on event with an action block
/// - bind on Event state
/// - calledAsFunction to signal
public class ImmutableEventBindableBase<EventStateType, ActionType> {
    
    public typealias ImmutableBindable = Bindable<EventStateType>.Immutable
    
    fileprivate var bindable: Bindable<EventStateType>
    
    fileprivate var action: ActionType
    
    public var asBindable: ImmutableBindable { return bindable.immutable }
    
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
    public func on<O: UIControl>(_ control:O, for event: UIControl.Event) -> Self {
        on(selector: #selector(self.valueChanged(sender:)), control, for: event)
        return self
    }
    
    @discardableResult
    public func observe(_ complection:@escaping (EventStateType) -> ()) -> Disposable {
        return bindable.observe(complection)
    }
    
    /// valueChanged call back when UIControl value is changed
    /// - Parameter sender: changed UIControl object
    /// - Parameter event: associated event that initiated this call
    @objc fileprivate func valueChanged(sender: UIControl) {
        signal()
    }
    
    @discardableResult
    public func signal() -> ImmutableBindable {
        //*** Note this function should be overriden from any subclass to call action ***
        bindable.immutable
    }
}

extension ImmutableEventableBase: Onable, Signallable, CallableAsFunction, CallableAsFunctionEvent { }
