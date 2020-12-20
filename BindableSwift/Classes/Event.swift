//
//  Event.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation

@propertyWrapper
public class Event {
    
    public typealias Immutable = ImmutableEvent
    public typealias ActionType = Immutable.ActionType
    public typealias CompletionType = Immutable.CompletionType
    
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
    
    public init(_ action: @escaping ActionType = {_ in}) {
        self.immutable = Immutable(action)
    }
    
    public func signalAll() {
        action() { [weak self] in
            self?.immutable.completion.forEach { $0.value() }
        }
    }
    
}

public class ImmutableEvent {
    
    public typealias ActionType = (CompletionType) -> Void
    public typealias CompletionType = () -> Void
    
    lazy fileprivate var primaryKey: ObjectIdentifier = ObjectIdentifier(self)
    
    fileprivate var action: ActionType
    fileprivate var completion: [String: CompletionType] = [:]
    
    public init(_ action: @escaping ActionType = {_ in}) {
        self.action = action
    }
    
    deinit {
        BindableDisposable.dispose(primaryKey: primaryKey)
    }
    
    @discardableResult
    public func event<O: UIControl>(_ control:O, event: UIControl.Event, _ completion: CompletionType? = nil) -> Disposable {
        control.addTarget(self, action: #selector(valueChanged(sender:event:)), for: event)
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(control)))\(event)"
        self.completion[secondaryKey] = completion
        return BindableDisposable(primaryKey, secondaryKey) { [weak self, weak control] in
            guard let self = self, let control = control else { return }
            control.removeTarget(self, action:  #selector(self.valueChanged(sender:event:)), for: event)
            self.completion.removeValue(forKey: secondaryKey)
        }
    }
    
    /// valueChanged call back when UIControl value is changed
    /// - Parameter sender: changed UIControl object
    @objc private func valueChanged(sender: UIControl, event: UIControl.Event) {
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(sender)))\(event)"
        let completion = self.completion[secondaryKey]
        action(completion ?? { })
    }
}

@propertyWrapper
public class Eventable<EventType> {
    
    public typealias Immutable = ImmutableEventable<EventType>
    public typealias ActionType = Immutable.ActionType
    public typealias CompletionType = Immutable.CompletionType
    
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
    
    public init(_ action: @escaping ActionType = {_ in}) {
        self.immutable = Immutable(action)
    }
    
    public func signalAll() {
        action() { [weak self] data in
            self?.immutable.completion.forEach { $0.value(data) }
        }
    }
    
}


public class ImmutableEventable<EventType> {
    
    public typealias ActionType = (CompletionType) -> Void
    public typealias CompletionType = (EventType) -> Void
    
    lazy fileprivate var primaryKey: ObjectIdentifier = ObjectIdentifier(self)
    
    fileprivate var action: ActionType
    fileprivate var completion: [String: CompletionType] = [:]
    
    public init(_ action: @escaping ActionType = {_ in}) {
        self.action = action
    }
    
    deinit {
        BindableDisposable.dispose(primaryKey: primaryKey)
    }
    
    @discardableResult
    public func event<O: UIControl>(_ control:O, event: UIControl.Event, _ completion: CompletionType? = nil) -> Disposable {
        control.addTarget(self, action: #selector(valueChanged(sender:event:)), for: event)
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(control)))\(event)"
        self.completion[secondaryKey] = completion
        return BindableDisposable(primaryKey, secondaryKey) { [weak self, weak control] in
            guard let self = self, let control = control else { return }
            control.removeTarget(self, action:  #selector(self.valueChanged(sender:event:)), for: event)
            self.completion.removeValue(forKey: secondaryKey)
        }
    }
    
    /// valueChanged call back when UIControl value is changed
    /// - Parameter sender: changed UIControl object
    @objc private func valueChanged(sender: UIControl, event: UIControl.Event) {
        let secondaryKey = "\(UInt(bitPattern: ObjectIdentifier(sender)))\(event)"
        let completion = self.completion[secondaryKey] ?? {_ in}
        action(completion)
    }
}

