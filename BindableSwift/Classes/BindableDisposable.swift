//
//  BindableDisposable.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation


public protocol Disposable {
    func dispose()
}

fileprivate let disposableBag = DisposableBag()

public class BindableDisposable: Disposable  {
    //MARK:- Private properties
    private var keyPair: KeyPair
    private var disposeBlock:() -> ()
    
    //MARK:- Initializer
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - primaryKey: primaryKey of BindableDisposable object
    ///   - secondaryKey: secondaryKey of BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    internal init(_ primaryKey:ObjectIdentifier, _ secondaryKey:String, _ disposeBlock: @escaping () -> ()) {
        self.disposeBlock = disposeBlock
        self.keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        disposableBag.set(primaryKey, secondaryKey, value: self)
    }
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - keyPair: keyPair for BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    internal init( _ keyPair: KeyPair,_ disposeBlock: @escaping () -> ()) {
        self.disposeBlock = disposeBlock
        self.keyPair = keyPair
        disposableBag.container[keyPair] = self
    }
    
    deinit {
        disposeBlock()
    }
    
    //MARK:- Public methods
    /// Short hand for dispose(primaryKey: )
    /// - Parameter referenceObject: primaryKey of diposeBlock(s) to dispose
    public static func dispose(_ referenceObject: AnyObject) {
        BindableDisposable.dispose(primaryKey: ObjectIdentifier(referenceObject))
    }
    
    /// Dispose a Bindable instance
    public func dispose() {
        print("before: \(disposableBag.container.count)")
        disposeBlock()
        disposableBag.remove(keyPair: keyPair)
        print("after: \(disposableBag.container.count)")
    }
    
    //MARK:- private methods
    /// dispose all with primaryKey
    /// - Parameter primaryKey: primaryKey of diposeBlock(s) to dispose
    internal static func dispose(primaryKey: ObjectIdentifier) {
        disposableBag.get(primaryKey: primaryKey)?.forEach { $0.value.dispose() }
    }
    /// dispose all with secondaryKey
    /// - Parameter primaryKey: secondaryKey of diposeBlock to dispose
    internal static func dispose(secondaryKey: String) {
        disposableBag.get(secondaryKey: secondaryKey)?.forEach{ $0.value.dispose() }
    }
    
    /// Container for seto fo disposable.
    /// Typically used manual memory management when the bindable object is not deallocated while the observer/binder object is deallocated
    /// - Parameters:
    ///   - referenceObject: object to reference this set of BindableDisposable
    ///   - bindableDisposables: array of BindableDisposable
    /// - Returns: return a BindableDisposable of the set of BindableDisposable to dipose later on
    @discardableResult
    public static func container(_ referenceObject: AnyObject, _ bindableDisposables:[Disposable]) -> Disposable {
        let keyPair = KeyPair(primary: ObjectIdentifier(referenceObject), secondary: "")
        if let bindableDisposable = disposableBag.container[keyPair] {
            let oldDisposeBlock = bindableDisposable.disposeBlock
            bindableDisposable.disposeBlock = {
                oldDisposeBlock()
                bindableDisposables.forEach { $0.dispose() }
            }
            return bindableDisposable
        }
        return BindableDisposable(keyPair) {
            bindableDisposables.forEach { $0.dispose() }
        }
    }
}

/// KeyPair is a pair of primary and secondary String keys
internal struct KeyPair: Hashable {
    var primary: ObjectIdentifier
    var secondary: String
}

/// DisposableBag contains all the DisposableBindable of the current active Bindable object
/// Used for dispose deallocated or to clean before rebinding with new bindable
private class DisposableBag {
    
    /// Main DisposableBag container
    fileprivate var container = [KeyPair: BindableDisposable]()
    private let lock = NSRecursiveLock()
    
    
    //MARK:- Getters
    func get(primaryKey:ObjectIdentifier) -> [KeyPair: BindableDisposable]? {
        return container.filter { $0.key.primary == primaryKey }
    }
    
    func get(secondaryKey:String) -> [KeyPair: BindableDisposable]? {
        return container.filter { $0.key.secondary == secondaryKey }
    }
    
    func get(_ primaryKey: ObjectIdentifier,_ secondaryKey: String) -> BindableDisposable? {
        return container[KeyPair(primary: primaryKey, secondary: secondaryKey)]
    }
    
    //MARK:- Setter
    func set(_ primaryKey:ObjectIdentifier, _ secondaryKey: String, value: BindableDisposable)  {
        lock.lock(); defer { lock.unlock() }
        let key = KeyPair(primary: primaryKey, secondary: secondaryKey)
        container[key] = value
    }
    
    //MARK:- Remove Methods
    func remove(secondaryKey: String) {
        lock.lock(); defer { lock.unlock() }
        container
            .filter { $0.key.secondary == secondaryKey }
            .forEach{ container.removeValue(forKey: $0.key) }
    }
    
    func remove(primaryKey: ObjectIdentifier) {
        lock.lock(); defer { lock.unlock() }
        container
            .filter { $0.key.primary == primaryKey }
            .forEach{ container.removeValue(forKey: $0.key) }
    }
    
    func remove(keyPair:KeyPair) {
        lock.lock(); defer { lock.unlock() }
        container.removeValue(forKey: keyPair)
    }
    
    func remove(_ primaryKey: ObjectIdentifier, _ secondaryKey: String) {
        lock.lock(); defer { lock.unlock() }
        let key = KeyPair(primary: primaryKey, secondary: secondaryKey)
        container.removeValue(forKey: key)
    }
}
