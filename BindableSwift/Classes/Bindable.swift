//
//  Bindable.swift
//  uCoach
//
//  Created by hossam.sherif on 12/06/2020.
//  Copyright © 2020 InsideTrack. All rights reserved.
//
import UIKit
import Foundation

/// Common transformation helper used on bind mehtod of bindable
public enum BindableMapper {
    static let boolToString: (Bool) -> String = String.init(_:)
    static let floatToString: (Float) -> String = String.init(_:)
    static let doubleToString: (Double) -> String = String.init(_:)
    static let intToString: (Int) -> String = String.init(_:)
}

/// Binding mode used in Bindable
public enum BindMode {
    case oneWay
    case towWay
}

protocol Disposable {
    func dispose()
}

/// KeyPair is a pair of primary and secondary String keys
fileprivate struct KeyPair: Hashable {
    var primary: ObjectIdentifier
    var secondary: ObjectKeyPathPair
}

fileprivate struct ObjectKeyPathPair: Hashable {
    var objectHash: ObjectIdentifier
    var keyPathHash: AnyHashable
    init(_ object: AnyObject, _ keyPath: AnyKeyPath) {
        objectHash = ObjectIdentifier(object)
        keyPathHash = ObjectIdentifier(keyPath)
    }
}

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
    fileprivate init(_ primaryKey:ObjectIdentifier, _ secondaryKey:ObjectKeyPathPair, _ disposeBlock: @escaping () -> ()) {
        self.disposeBlock = disposeBlock
        self.keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
        DisposableBag[primaryKey, secondaryKey: secondaryKey] = self
    }
    
    /// BindableDisposable init
    /// - Parameters:
    ///   - keyPair: keyPair for BindableDisposable object
    ///   - disposeBlock: disposeBlock to be fired on dispose
    /// - Returns: BindableDisposable instance
    fileprivate init( _ keyPair: KeyPair,_ disposeBlock: @escaping () -> ()) {
        self.disposeBlock = disposeBlock
        self.keyPair = keyPair
        DisposableBag[keyPair: keyPair] = self
    }
    
    //MARK:- Public methods
    /// Short hand for dispose(primaryKey: )
    /// - Parameter referenceObject: primaryKey of diposeBlock(s) to dispose
    public static func dispose(_ referenceObject: AnyObject) {
        BindableDisposable.dispose(primaryKey: ObjectIdentifier(referenceObject))
    }
    
    /// Dispose a Bindable instance
    public func dispose() {
        disposeBlock()
        print("before: \((DisposableBag.primaryContainer.count, DisposableBag.secondaryContainer.count, DisposableBag.manualContainer.count))")
        if let _ = DisposableBag.remove(keyPair: keyPair) {
            let key = UInt(bitPattern: keyPair.primary).description
            DisposableBag.manualContainer.removeValue(forKey: key)
        }
        print("after: \((DisposableBag.primaryContainer.count, DisposableBag.secondaryContainer.count, DisposableBag.manualContainer.count))")
    }
    
    //MARK:- private methods
    /// dispose all with primaryKey
    /// - Parameter primaryKey: primaryKey of diposeBlock(s) to dispose
    static func dispose(primaryKey: ObjectIdentifier) {
        DisposableBag[primaryKey: primaryKey].forEach { DisposableBag[secondaryKey: $0]?.dispose() }
    }
    /// dispose all with secondaryKey
    /// - Parameter primaryKey: secondaryKey of diposeBlock to dispose
    fileprivate static func dispose(secondaryKey: ObjectKeyPathPair) {
        DisposableBag[secondaryKey: secondaryKey]?.dispose()
    }
    
    /// Container for seto fo disposable.
    /// Typically used manual memory management when the bindable object is not deallocated while the observer/binder object is deallocated
    /// - Parameters:
    ///   - referenceObject: object to reference this set of BindableDisposable
    ///   - bindableDisposables: array of BindableDisposable
    /// - Returns: return a BindableDisposable of the set of BindableDisposable to dipose later on
    @discardableResult
    public static func container(_ referenceObject: AnyObject, _ bindableDisposables:[BindableDisposable]) -> BindableDisposable {
        let key = UInt(bitPattern: ObjectIdentifier(referenceObject)).description
        if let bindableDisposable = DisposableBag.manualContainer[key] {
            let oldDisposeBlock = bindableDisposable.disposeBlock
            bindableDisposable.disposeBlock = {
                oldDisposeBlock()
                bindableDisposables.forEach { $0.dispose() }
            }
            return bindableDisposable
        }
        return BindableDisposable(ObjectIdentifier(referenceObject), ObjectKeyPathPair(referenceObject, \BindableDisposable.self)) {
            bindableDisposables.forEach { $0.dispose() }
        }
    }
    
    /// DisposableBag contains all the DisposableBindable of the current active Bindable object
    /// Used for dispose deallocated or to clean before rebinding with new bindable
    private class DisposableBag {
        
        /// Main DisposableBag container
        fileprivate static var primaryContainer = [ObjectIdentifier: [ObjectKeyPathPair]]()
        fileprivate static var secondaryContainer = [ObjectKeyPathPair: (ObjectIdentifier, BindableDisposable)]()
        fileprivate static var manualContainer = [String: BindableDisposable]()
        
        fileprivate static let lock = NSRecursiveLock()
        
        //MARK:- subscripts
        static subscript(primaryKey primaryKey: ObjectIdentifier) -> [ObjectKeyPathPair] {
            get {
                return DisposableBag.primaryContainer[primaryKey] ?? []
            }
            set {
                lock.lock(); defer { lock.unlock() }
                DisposableBag.primaryContainer[primaryKey] = newValue
            }
        }
        
        static subscript(secondaryKey secondaryKey: ObjectKeyPathPair) -> BindableDisposable? {
            get {
                return DisposableBag.secondaryContainer[secondaryKey]?.1
            }
        }
        
        static subscript(primaryKey: ObjectIdentifier, secondaryKey secondaryKey: ObjectKeyPathPair) -> BindableDisposable? {
            get {
                return DisposableBag.secondaryContainer[secondaryKey]?.1
            }
            set {
                lock.lock(); defer { lock.unlock() }
                guard let newValue = newValue else { return }
                DisposableBag.secondaryContainer[secondaryKey] = (primaryKey, newValue)
                DisposableBag.primaryContainer[primaryKey]?.append(secondaryKey)
            }
        }
        
        static subscript(keyPair keyPair: KeyPair) -> BindableDisposable? {
            get {
                return DisposableBag.secondaryContainer[keyPair.secondary]?.1
            }
            set {
                lock.lock(); defer { lock.unlock() }
                guard let newValue = newValue else { return }
                DisposableBag.secondaryContainer[keyPair.secondary] = (keyPair.primary, newValue)
                DisposableBag.primaryContainer[keyPair.primary]?.append(keyPair.secondary)
            }
        }
        
        //MARK:- Getters
        
        //MARK:- Setter
        fileprivate static func set(_ primaryKey:ObjectIdentifier, _ secondaryKey: ObjectKeyPathPair, value: BindableDisposable)  {
            lock.lock(); defer { lock.unlock() }
            DisposableBag.primaryContainer[primaryKey]?.append(secondaryKey)
            DisposableBag.secondaryContainer[secondaryKey] = (primaryKey, value)
        }
        
        //MARK:- Remove Methods
        static func remove(secondaryKey: ObjectKeyPathPair) {
            lock.lock(); defer { lock.unlock() }
            if let primaryKey = DisposableBag.secondaryContainer.removeValue(forKey: secondaryKey)?.0 {
                DisposableBag[primaryKey: primaryKey] = DisposableBag[primaryKey: primaryKey].filter { $0.hashValue == secondaryKey.hashValue }
            }
        }
        @discardableResult
        static func remove(primaryKey: ObjectIdentifier) -> [ObjectKeyPathPair]? {
            lock.lock(); defer { lock.unlock() }
            DisposableBag[primaryKey: primaryKey]
                .forEach{ DisposableBag.secondaryContainer.removeValue(forKey: $0) }
            return DisposableBag.primaryContainer.removeValue(forKey: primaryKey)
        }
        
        @discardableResult
        static func remove(keyPair: KeyPair) -> BindableDisposable? {
            return DisposableBag.remove(keyPair.primary, keyPair.secondary)
        }
        
        static func remove(_ primaryKey: ObjectIdentifier, _ secondaryKey: ObjectKeyPathPair) -> BindableDisposable? {
            lock.lock(); defer { lock.unlock() }
            DisposableBag[primaryKey: primaryKey] = DisposableBag[primaryKey: primaryKey].filter { $0.hashValue == secondaryKey.hashValue }
            return DisposableBag.secondaryContainer.removeValue(forKey: secondaryKey)?.1
        }
    }

    
//    /// DisposableBag contains all the DisposableBindable of the current active Bindable object
//    /// Used for dispose deallocated or to clean before rebinding with new bindable
//    private class DisposableBag {
//
//        /// Main DisposableBag container
//        fileprivate static var container = [KeyPair: BindableDisposable]()
//
//        fileprivate static let lock = NSRecursiveLock()
//
//        //MARK:- subscripts
//        static subscript(primaryKey: ObjectIdentifier, secondaryKey: String) -> BindableDisposable? {
//            get {
//                let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
//                return DisposableBag.container[keyPair]
//            }
//            set {
//
//                let keyPair = KeyPair(primary: primaryKey, secondary: secondaryKey)
//                DisposableBag.container[keyPair] = newValue
//            }
//        }
//        static subscript(primaryKey primaryKey: ObjectIdentifier) -> [KeyPair: BindableDisposable]? {
//            get {
//                return DisposableBag.container.filter { $0.key.primary == primaryKey }
//            }
//        }
//
//        static subscript(secondaryKey secondaryKey: String) -> [KeyPair: BindableDisposable]? {
//            get {
//                return DisposableBag.container.filter { $0.key.secondary == secondaryKey }
//            }
//        }
//
//        static subscript(keyPair keyPair: KeyPair) -> BindableDisposable? {
//            get {
//                return DisposableBag.container[keyPair]
//            }
//            set {
//                lock.lock(); defer { lock.unlock() }
//                DisposableBag.container[keyPair] = newValue
//            }
//        }
//        //MARK:- Getters
//        static func get(secondaryKey:String) -> [KeyPair: BindableDisposable]? {
//            return DisposableBag.container.filter { $0.key.secondary == secondaryKey }
//        }
//        static func get(primaryKey:ObjectIdentifier) -> [KeyPair: BindableDisposable]? {
//            return DisposableBag.container.filter { $0.key.primary == primaryKey }
//        }
//        static func get(_ primaryKey: ObjectIdentifier,_ secondaryKey: String) -> BindableDisposable? {
//            return DisposableBag.container[KeyPair(primary: primaryKey, secondary: secondaryKey)]
//        }
//
//        //MARK:- Setter
//        static func set(_ primaryKey:ObjectIdentifier, _ secondaryKey: String, value: BindableDisposable)  {
//            lock.lock(); defer { lock.unlock() }
//            let key = KeyPair(primary: primaryKey, secondary: secondaryKey)
//            DisposableBag.container[key] = value
//        }
//
//        //MARK:- Remove Methods
//        static func remove(secondaryKey: String) {
//            lock.lock(); defer { lock.unlock() }
//            DisposableBag.container
//                .filter { $0.key.secondary == secondaryKey }
//                .forEach{ DisposableBag.container.removeValue(forKey: $0.key) }
//        }
//
//        static func remove(primaryKey: ObjectIdentifier) {
//            lock.lock(); defer { lock.unlock() }
//            DisposableBag.container
//                .filter { $0.key.primary == primaryKey }
//                .forEach{ DisposableBag.container.removeValue(forKey: $0.key) }
//        }
//
//        static func remove(keyPair:KeyPair) {
//            lock.lock(); defer { lock.unlock() }
//            DisposableBag.container.removeValue(forKey: keyPair)
//        }
//
//        static func remove(_ primaryKey: ObjectIdentifier, _ secondaryKey: String) {
//            lock.lock(); defer { lock.unlock() }
//            let key = KeyPair(primary: primaryKey, secondary: secondaryKey)
//            DisposableBag.container.removeValue(forKey: key)
//        }
//    }
}

/// AbstractBindable to constrain Bindable methods and property
protocol AbastractBindable {
    associatedtype BindingType
    
    /// Current value
    var value:BindingType { get }
    
    /// Observe on bindable
    /// - Parameters:
    ///   - sourceKeyPath: source key path for the current bindable
    ///   - completion: completion handler called after each update from source to object
    @discardableResult
    func observe<T>(_ sourceKeyPath: KeyPath<BindingType, T>, _ completion: @escaping (T) -> ()) -> BindableDisposable
    
    /// bind an object to this bindable
    /// - Parameters:
    ///   - sourceKeyPath: source key path for the current bindable
    ///   - object: object to bind on
    ///   - objectKeyPath: object key path
    ///   - mode: binding mode type
    ///   - mapper: transfomation mapper from source to object
    ///   - completion: completion handler called after each update from source to object
    @discardableResult
    func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                  to object: O,
                                  _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                  mode: BindMode,
                                  mapper: @escaping (T) -> R,
                                  completion: ((T) -> ())?) -> BindableDisposable
}
//MARK:- Default AbastractBindable paramteres
extension AbastractBindable {
    
    @discardableResult
    func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                  to object: O,
                                  _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                  mode: BindMode = .oneWay,
                                  mapper: @escaping (T) -> R = { $0 as! R },
                                  completion: ((T) -> ())? = nil) -> BindableDisposable {
        bind(sourceKeyPath, to: object, objectKeyPath, mode: mode, mapper: mapper, completion: completion)
    }
}


/// Bindable<BindingType> generic mutable binding
/// Typically should be used in viewModels by `_` prefix when used as propertyWrapper to be able to access value setter
@propertyWrapper
public class Bindable<BindingType>: AbastractBindable {
    public typealias Immutable = ImmutableBindable<BindingType>
    //MARK:- Properties
    
    /// BindableImmutable instance
    var immutable: Immutable
    
    /// propertyWrapper wrapper value of type BindableImmutable<BindingType>
    /// which typically should be used by view to provide read only value
    public var wrappedValue: Immutable {
        return immutable
    }
    
    /// Main init for Bindable<BindingType>
    /// - Parameter immutable: BindableImmutable<BindingType> wrapped by this class
    public init(immutable: Immutable = ImmutableBindable()) {
        self.immutable = immutable
    }
    
    public init(_ value: BindingType?) {
        self.immutable = ImmutableBindable(value)
    }
    
    /// represent current value and changes to this property will publish updated value to all observers
    public var value:BindingType {
        get {
            /*
             * Note:
             * If you try to directly unwrap currentValue it will crash with Optional BindingType.
             * Contional casting on the other hand can have optional outcome with nil value in it.
             */
            return immutable.currentValue as! BindingType
        }
        set {
            immutable.currentValue = newValue
            immutable.observers.forEach{ $1(newValue) }
        }
    }
    
    /// projectedValue from @propertyWrapper to easily access value from Bindable instance
    /// While mantaing exported value property for ImmutableBindable
    open var projectedValue: BindingType {
        get {
            return value
        }
        set {
            value = newValue
        }
    }
    
    @discardableResult
    public func observe<T>(_ sourceKeyPath: KeyPath<BindingType, T>, _ completion: @escaping (T) -> ()) -> BindableDisposable {
        return immutable.observe(sourceKeyPath, completion)
    }
    
    @discardableResult
    public func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                  to object: O,
                                  _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                  mode: BindMode = .oneWay,
                                  mapper: @escaping (T) -> R = { $0 as! R },
                                  completion: ((T) -> ())? = nil) -> BindableDisposable {
        return immutable.bind(sourceKeyPath, to: object, objectKeyPath, mode: mode, mapper: mapper, completion: completion)
    }
}

/// Immutable representation of bindable object
public class ImmutableBindable<BindingType>: AbastractBindable {
    
    //MARK: Private properties
    
    /// Observers dictionary
    /// key is a string which is the result of getObserverHash method
    /// value is the completion block called when value is updated
    fileprivate var observers = [String: (BindingType) -> ()]()
    /// concrete representation on the currentValue
    fileprivate var currentValue: BindingType?
    /// current keyPath for the observer object used in .towWay BindingMode
    private var keyPath: AnyKeyPath?
    
    //Current ImmutableBindable primaryKey used with DisposabkeBag
    lazy fileprivate var primaryKey: ObjectIdentifier = ObjectIdentifier(self)
    
    //MARK: Properties
    /// Current value
    public var value:BindingType {
        get {
            /*
             * Note:
             * If you try to directly unwrap currentValue it will crash with Optional BindingType.
             * Contional casting on the other hand can have optional outcome with nil value in it.
             */
            return currentValue as! BindingType
        }
    }
    
    //MARK: Methods
    
    /// Main init for BindableImmutable<BindingType>
    /// - Parameter value: initial value wrapped on this bindable object, default value = nil
    public init(_ value: BindingType? = nil) {
        currentValue = value
    }
    
    /// cleaning before object deinit
    deinit {
        BindableDisposable.dispose(primaryKey: primaryKey)
        NotificationCenter.default.removeObserver(self)
    }
    
    @discardableResult
    public func observe<T>(_ sourceKeyPath: KeyPath<BindingType, T>, _ completion: @escaping (T) -> ()) -> BindableDisposable {
        currentValue.map { completion($0[keyPath: sourceKeyPath]) }
        let secondaryKey = UUID().uuidString
        observers[secondaryKey] = { completion($0[keyPath: sourceKeyPath]) }
        let BindableDisposableSecondaryKey = ObjectKeyPathPair(secondaryKey as AnyObject, \String.self)
        return  BindableDisposable(primaryKey, BindableDisposableSecondaryKey) { [weak self] in
            self?.observers.removeValue(forKey: secondaryKey)
        }
    }
    
    /// unbind from an object
    /// - Parameters:
    ///   - object: object to unbind from
    ///   - objectKeyPath: objectKeyPath to unbind from
    ///   - mode: binding mode type
    private func unbind<O: AnyObject, R>(from object: O,
                                         _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                         mode:BindMode = .oneWay) {
        if mode == .towWay {
            removeTowWayBind(object)
        }
        observers.removeValue(forKey: getObserverHash(object, objectKeyPath))
    }
    
    @discardableResult
    public func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                  to object: O,
                                  _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                  mode: BindMode = .oneWay,
                                  mapper: @escaping (T) -> R = { $0 as! R },
                                  completion: ((T) -> ())? = nil) -> BindableDisposable {
        
        if mode == .towWay {
            addTowWayBinding(object, objectKeyPath)
        }
        return addObserver(for: object, objectKeyPath) { [weak object, weak objectKeyPath] observed in
            guard let object = object, let objectKeyPath = objectKeyPath else { return }
            let value = observed[keyPath: sourceKeyPath]
            let mapped = mapper(value)
            object[keyPath: objectKeyPath] = mapped
            completion?(value)
        }
    }
    
    //MARK: Private methods
    
    /// valueChanged call back when UIControl value is changed
    /// - Parameter sender: changed UIControl object
    @objc private func valueChanged( sender: UIControl) {
        if let keyPath = keyPath, let newValue = sender[keyPath: keyPath] as? BindingType {
            currentValue = newValue
            observers.forEach{ $1(newValue) }
        }
    }
    
    /// Special case for UITextView text did change from NotificationCenter
    /// - Parameter notification: notification object
    @objc private func textViewValueChanged(_ notification: Notification) {
        if let textView = notification.object as? UITextView,
           let keyPath = keyPath,
           observers[getObserverHash(textView, keyPath)] != nil,
           let newValue = textView[keyPath: keyPath] as? BindingType {
            currentValue = newValue
            observers.forEach{ $1(newValue) }
        }
    }
    
    /// Add observer object to observers array
    /// - Parameters:
    ///   - object: observer object
    ///   - objectKeyPath: key path of observer object to be changed on value change
    ///   - completion: completion handler to be called when value is changed
    private func addObserver<O: AnyObject, R>(for object: O,
                                              _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                              mode: BindMode = .oneWay,
                                              completion: @escaping (BindingType) -> Void) -> BindableDisposable {
        let observerKey = getObserverHash(object, objectKeyPath)
        let secondaryKey = ObjectKeyPathPair(object, objectKeyPath)
        
        //Dipose previous binding from object/objectKeyPath pair
        BindableDisposable.dispose(secondaryKey: secondaryKey)
        // if there is a initial value run the completion
        currentValue.map { completion($0) }
        observers[observerKey] = { completion($0) }
        return BindableDisposable(primaryKey, secondaryKey) { [weak self, weak object, weak objectKeyPath] in
            guard let object = object, let objectKeyPath = objectKeyPath else { return }
            self?.unbind(from: object, objectKeyPath, mode: mode)
        }
    }
    
    
    /// Helper function to get uniqie hash for object keyPath combination
    /// - Parameters:
    ///   - object: observer object
    ///   - objectKeyPath: keyPath of object
    /// - Returns: String unique hash representing object keyPath combination
    private func getObserverHash<O: AnyObject>(_ object:O,
                                               _ objectKeyPath: AnyKeyPath) -> String {
        let objectHash = UInt(bitPattern: ObjectIdentifier(object)).description
        let keyPathHash = UInt(bitPattern: ObjectIdentifier(objectKeyPath)).description
        return objectHash + keyPathHash
    }
    
    /// Add tow way binding from object to bindable value
    /// - Parameters:
    ///   - object: object to bind on
    ///   - objectKeyPath: keyPath of object to bind on
    private func addTowWayBinding<O: AnyObject, R>(_ object: O,
                                                   _ objectKeyPath: ReferenceWritableKeyPath<O, R>) {
        if let control = object as? UIControl {
            control.addTarget(self, action: #selector(valueChanged), for: [.editingChanged, .valueChanged])
        }else if object is UITextView {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(textViewValueChanged(_:)),
                                                   name: UITextView.textDidChangeNotification,
                                                   object: nil)
        }
        keyPath = objectKeyPath
    }
    
    /// remove tow way bind from an object
    /// - Parameter object: object to remove binding from
    fileprivate func removeTowWayBind<O: AnyObject>(_ object: O) {
        if let control = object as? UIControl {
            control.removeTarget(self, action: #selector(valueChanged), for: [.editingChanged, .valueChanged])
        }else if object is UITextView {
            NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
        }
        keyPath = nil
    }
}
