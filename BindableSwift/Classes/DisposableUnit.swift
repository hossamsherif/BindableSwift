//
//  BindableDisposable.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation


/// Diposable protocol to dispose any logic/data
public protocol Disposable {
    func dispose()
}

/// Diposable Unit conform to Disposable protocol for any disposable component made
class DisposableUnit: Disposable  {
    //MARK:- Private properties
    private var keyPair: KeyPair
    fileprivate var disposeBlock:() -> ()
    
    //MARK:- Internal initializer
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - primaryKey: primaryKey of BindableDisposable object
    ///   - secondaryKey: secondaryKey of BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    init(_ primaryKey:ObjectIdentifier, _ secondaryKey:String, _ disposeBlock: @escaping () -> ()) {
        self.disposeBlock = disposeBlock
        self.keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        DisposableBag.shared.set(primaryKey, secondaryKey, value: self)
    }
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - keyPair: keyPair for BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    init( _ keyPair: KeyPair,_ disposeBlock: @escaping () -> ()) {
        self.disposeBlock = disposeBlock
        self.keyPair = keyPair
        DisposableBag.shared.container[keyPair] = self
    }
    
//    deinit {
//        disposeBlock()
//    }
    
    //MARK:- Public methods

    /// Dispose a Bindable instance
    public func dispose() {
        print("before: \(DisposableBag.shared.container.count)")
        disposeBlock()
        DisposableBag.shared.remove(keyPair: keyPair)
        print("after: \(DisposableBag.shared.container.count)")
    }

}

/// KeyPair is a pair of primary and secondary String keys
struct KeyPair: Hashable {
    var primary: ObjectIdentifier
    var secondary: String
}

/// DisposableBag contains all the DisposableBindable of the current active Bindable object
/// Used for dispose deallocated or to clean before rebinding with new bindable
public class DisposableBag {
    //MARK:- Private properties
    /// Main DisposableBag container
    fileprivate var container = [KeyPair: DisposableUnit]()
    private let lock = NSRecursiveLock()
    
    //MARK:- singleton
    
    fileprivate static let shared = DisposableBag()
    
    fileprivate init() {}
    
    //MARK:- Public methods
    /// Short hand for dispose(primaryKey: )
    /// - Parameter referenceObject: primaryKey of diposeBlock(s) to dispose
    public static func dispose(_ referenceObject: AnyObject) {
        DisposableBag.dispose(primaryKey: ObjectIdentifier(referenceObject))
    }
    
    //MARK:- Internal methods
    /// dispose all with primaryKey
    /// - Parameter primaryKey: primaryKey of diposeBlock(s) to dispose
    static func dispose(primaryKey: ObjectIdentifier) {
        shared.get(primaryKey: primaryKey)?.forEach { $0.value.dispose() }
    }
    /// dispose all with secondaryKey
    /// - Parameter primaryKey: secondaryKey of diposeBlock to dispose
    static func dispose(secondaryKey: String) {
        shared.get(secondaryKey: secondaryKey)?.forEach{ $0.value.dispose() }
    }
    
    //MARK:- Private methods
    /// Container for seto fo disposable.
    /// Typically used manual memory management when the bindable object is not deallocated while the observer/binder object is deallocated
    /// - Parameters:
    ///   - referenceObject: object to reference this set of BindableDisposable
    ///   - bindableDisposables: array of BindableDisposable
    /// - Returns: return a BindableDisposable of the set of BindableDisposable to dipose later on
    @discardableResult
    public static func container(_ referenceObject: AnyObject, _ bindableDisposables:[Disposable]) -> Disposable {
        let keyPair = KeyPair(primary: ObjectIdentifier(referenceObject), secondary: "")
        if var bindableDisposable = shared.container[keyPair] {
            let oldDisposeBlock = bindableDisposable.disposeBlock
            bindableDisposable.disposeBlock = {
                oldDisposeBlock()
                bindableDisposables.forEach { $0.dispose() }
            }
            return bindableDisposable
        }
        return DisposableUnit(keyPair) {
            bindableDisposables.forEach { $0.dispose() }
        }
    }
    
    
    //MARK:- Getters
    func get(primaryKey:ObjectIdentifier) -> [KeyPair: DisposableUnit]? {
        return container.filter { $0.key.primary == primaryKey }
    }
    
    func get(secondaryKey:String) -> [KeyPair: DisposableUnit]? {
        return container.filter { $0.key.secondary == secondaryKey }
    }
    
    func get(_ primaryKey: ObjectIdentifier,_ secondaryKey: String) -> DisposableUnit? {
        return container[KeyPair(primary: primaryKey, secondary: secondaryKey)]
    }
    
    //MARK:- Setter
    func set(_ primaryKey:ObjectIdentifier, _ secondaryKey: String, value: DisposableUnit)  {
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
