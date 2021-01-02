//
//  BindableDisposable.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation


/// Diposable protocol to dispose any logic/data
public protocol Disposable {
    var isDisposed: Bool { get }
    func dispose()
}

/// Diposable Unit conform to Disposable protocol for any disposable component made
struct DisposableUnit: Disposable  {
    //MARK:- Private properties
    public var isDisposed = false
    private var keyPair: KeyPair
    private var disposableBag: DisposableBag?
    var disposeBlock:DisposeBlock
    
    //MARK:- Internal initializer
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - primaryKey: primaryKey of BindableDisposable object
    ///   - secondaryKey: secondaryKey of BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    init(_ primaryKey:ObjectIdentifier,
         _ secondaryKey:String,
         disposableBag: DisposableBag? = nil,
         _ disposeBlock: @escaping () -> ()) {
        self.keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        self.disposableBag = disposableBag ?? .shared
        self.disposeBlock = DisposeBlock(disposeBlock)
        self.disposableBag?.set(primaryKey, secondaryKey, value: self)
    }
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - keyPair: keyPair for BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    init( _ keyPair: KeyPair,
          disposableBag: DisposableBag? = nil,
          _ disposeBlock: @escaping () -> ()) {
        self.keyPair = keyPair
        self.disposableBag = disposableBag ?? .shared
        self.disposeBlock = DisposeBlock(disposeBlock)
        self.disposableBag?.container[keyPair] = self
    }
    
//    deinit {
//        dispose()
//    }
    
    //MARK:- Public methods
    /// Dispose a Bindable instance
    public func dispose() {
        print("before: \(disposableBag?.container.count ?? -1)")
        guard !disposeBlock.isDisposed else { return }
        disposeBlock.isDisposed = true
        disposeBlock()
        disposableBag?.remove(keyPair: keyPair)
        print("after: \(disposableBag?.container.count ?? -1)")
    }

    class DisposeBlock {
        var action: () -> ()
        var isDisposed = false
        init( _ action: @escaping () -> ()) {
            self.action = action
        }
        func callAsFunction() {
            action()
        }
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
    var container = [KeyPair: DisposableUnit]()
    private let lock = NSRecursiveLock()
    
    //MARK:- singleton
    
    static let shared = DisposableBag()
    
    deinit {
        container.forEach { $0.value.dispose() }
        container.removeAll()
    }
    
    public init() {}
    
    /// dispose all with primaryKey
    /// - Parameter primaryKey: primaryKey of diposeBlock(s) to dispose
    func dispose(primaryKey: ObjectIdentifier) {
        get(primaryKey: primaryKey)?.forEach { $0.value.dispose() }
    }
    
    /// dispose all with secondaryKey
    /// - Parameter primaryKey: secondaryKey of diposeBlock to dispose
    func dispose(secondaryKey: String) {
        get(secondaryKey: secondaryKey)?.forEach{ $0.value.dispose() }
    }
    
    /// Short hand for dispose(primaryKey: )
    /// - Parameter referenceObject: primaryKey of diposeBlock(s) to dispose
    public func dispose(_ referenceObject: AnyObject) {
        get(primaryKey: ObjectIdentifier(referenceObject))?.forEach { $0.value.dispose() }
    }
    
    /// Container for a set of disposable.
    /// Typically used manual memory management when the bindable object is not deallocated while the observer/binder object is deallocated
    /// - Parameters:
    ///   - referenceObject: object to reference this set of BindableDisposable
    ///   - bindableDisposables: array of BindableDisposable
    /// - Returns: return a BindableDisposable of the set of BindableDisposable to dipose later on
    @discardableResult
    public func container(_ referenceObject: AnyObject,
                   _ bindableDisposables:[Disposable]) -> Disposable {
        let keyPair = KeyPair(primary: ObjectIdentifier(referenceObject), secondary: "")
        if let bindableDisposable = container[keyPair] {
            let oldDisposeBlock = bindableDisposable.disposeBlock.action
            bindableDisposable.disposeBlock.action = { //[weak bindableDisposable] in
                oldDisposeBlock()
                bindableDisposable.disposeBlock.isDisposed = false
                bindableDisposables.forEach { $0.dispose() }
            }
            return bindableDisposable
        }
        return DisposableUnit(keyPair, disposableBag: self) {
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

//MARK:- Static methods for shared instance
extension DisposableBag {
    //MARK:- Internal methods
    /// dispose all with primaryKey
    /// - Parameter primaryKey: primaryKey of diposeBlock(s) to dispose
    static func dispose(primaryKey: ObjectIdentifier) {
        shared.dispose(primaryKey: primaryKey)
    }
    /// dispose all with secondaryKey
    /// - Parameter primaryKey: secondaryKey of diposeBlock to dispose
    static func dispose(secondaryKey: String) {
        shared.dispose(secondaryKey: secondaryKey)
    }
    
    //MARK:- Public methods
    /// Short hand for dispose(primaryKey: )
    /// - Parameter referenceObject: primaryKey of diposeBlock(s) to dispose
    public static func dispose(_ referenceObject: AnyObject) {
        shared.dispose(referenceObject)
    }
    
    /// Container for a set of disposable with default shared instance
    /// Typically used manual memory management when the bindable object is not deallocated while the observer/binder object is deallocated
    /// - Parameters:
    ///   - referenceObject: object to reference this set of BindableDisposable
    ///   - bindableDisposables: array of BindableDisposable
    /// - Returns: return a BindableDisposable of the set of BindableDisposable to dipose later on
    @discardableResult
    public static func container(_ referenceObject: AnyObject,
                                 _ bindableDisposables:[Disposable]) -> Disposable {
        return shared.container(referenceObject, bindableDisposables)
    }
    
}
