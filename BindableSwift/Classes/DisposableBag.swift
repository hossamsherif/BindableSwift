//
//  BindableDisposable.swift
//  BindableSwift
//
//  Created by Hossam Sherif on 12/20/20.
//

import Foundation


/// Diposable protocol to dispose any logic/data
public protocol Disposable: class {
    var isDisposed: Bool { get }
    func dispose()
}

/// Diposable Unit conform to Disposable protocol for any disposable component made
public class DisposableUnit: Disposable {
    //MARK:- Private properties
    public var isDisposed = false
    private(set) var keyPair: KeyPair
    private(set) weak var disposableBag: DisposableBag?
    private(set) var disposeBlock: (() -> ())?
    
    //MARK:- Internal initializer
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - referenceObject: AnyObject reference
    ///   - secondaryKey: secondaryKey of BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    public convenience init(_ referenceObject: AnyObject,
                            _ secondaryKey:String,
                            disposableBag: DisposableBag? = nil,
                            _ disposeBlock: @escaping () -> ()) {
        self.init(ObjectIdentifier(referenceObject), secondaryKey, disposableBag: disposableBag, disposeBlock)
    }
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - primaryKey: primaryKey of BindableDisposable object
    ///   - secondaryKey: secondaryKey of BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    public convenience init(_ primaryKey:ObjectIdentifier,
                            _ secondaryKey:String,
                            disposableBag: DisposableBag? = nil,
                            _ disposeBlock: @escaping () -> ()) {
        let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        self.init(keyPair, disposableBag: disposableBag, disposeBlock)
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
        self.disposeBlock = disposeBlock
        self.disposableBag = disposableBag ?? .shared
        self.disposableBag?.container[keyPair] = self
    }
    
    //MARK:- Public methods
    /// Dispose a Bindable instance
    public func dispose() {
//        print("before: \(disposableBag?.container.count ?? -1)")
        guard !isDisposed else { return }
        isDisposed = true
        disposeBlock?()
        disposableBag?.remove(keyPair: keyPair)
//        print("after: \(disposableBag?.container.count ?? -1)")
        disposableBag = nil
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
    var container = [KeyPair: Disposable]()
    private let lock = NSRecursiveLock()
    
    //MARK:- singleton
    
    static let shared = DisposableBag()
    
    deinit {
        container.forEach { $0.value.dispose() }
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
        let primaryKey = ObjectIdentifier(referenceObject)
        get(primaryKey: primaryKey)?.forEach { $0.value.dispose() }
    }
    
    //MARK:- Getters
    func get(primaryKey:ObjectIdentifier) -> [KeyPair: Disposable]? {
        return container.filter { $0.key.primary == primaryKey }
    }
    
    func get(secondaryKey:String) -> [KeyPair: Disposable]? {
        return container.filter { $0.key.secondary == secondaryKey }
    }
    
    func get(_ primaryKey: ObjectIdentifier,_ secondaryKey: String) -> Disposable? {
        return container[KeyPair(primary: primaryKey, secondary: secondaryKey)]
    }
    
    //MARK:- Setter
    func set(_ primaryKey:ObjectIdentifier, _ secondaryKey: String, value: Disposable)  {
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
}
