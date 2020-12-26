//
//  Bindable.swift
//  uCoach
//
//  Created by hossam.sherif on 12/06/2020.
//  Copyright © 2020 InsideTrack. All rights reserved.
//
import UIKit
import Foundation

/// Binding mode used in Bindable
public enum BindMode {
    case oneWay
    case towWay
}

/// Binding span used in Bindable
/// .once disposed after one observation
/// .times(_ time: Int) dispose after number of `time` observation
/// .always should be disposed DiposableBag (automatically or manually)
public enum Span {
    case once
    case times(_ time:Int)
    case always
    
    mutating func tik() -> Bool {
        switch self {
        case .once: return true
        case .times(let time):
            self = .times(time-1)
            return time <= 0
        case .always: return false
        }
    }
}

/// AbstractBindable to constrain Bindable methods and property
public protocol AbastractBindable {
    associatedtype BindingType
    
    /// Current value
    var value: BindingType? { get }
    
    /// Observe on bindable
    /// - Parameters:
    ///   - sourceKeyPath: source key path for the current bindable
    ///   - span: binding life time - default: .always
    ///   - completion: completion handler called after each update from source to object
    @discardableResult
    func observe<T>(_ sourceKeyPath: KeyPath<BindingType, T>,
                    _ span: Span,
                    _ completion: @escaping (T) -> ()) -> Disposable
    
    /// bind an object to this bindable
    /// - Parameters:
    ///   - sourceKeyPath: source key path for the current bindable - default: \BindingType.self
    ///   - object: object to bind on
    ///   - objectKeyPath: object key path
    ///   - mode: binding mode type - default: .onWay
    ///   - mapper: transfomation mapper from source to object
    ///   - span: binding life time - default: .always
    ///   - completion: completion handler called after each update from source to object - default: nil
    @discardableResult
    func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                  to object: O,
                                  _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                  mode: BindMode,
                                  mapper: @escaping (T) -> R,
                                  _ span: Span,
                                  completion: ((T) -> ())?) -> Disposable
    
    
    /// Return a new Bindable builder
    /// - Parameters:
    ///   - sourceKeyPath: source key path for the current bindable - default: \BindingType.self
    ///   - object: object to bind on
    ///   - objectKeyPath: object key path
    func bindOn<T, O:AnyObject, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                          _ object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, R>) -> BindableBuilder<BindingType, T, O, R>
    
    /// Return a new Observable builder
    ///   - sourceKeyPath: source key path for the current bindable
    func observeOn<T>(_ sourceKeyPath: KeyPath<BindingType, T>) -> ObservableBuilder<BindingType, T>
}
//MARK:- Default AbastractBindable paramteres
public extension AbastractBindable {
    
    @discardableResult
    func observe(_ span: Span = .always, _ completion: @escaping (BindingType) -> ()) -> Disposable {
        observe(\BindingType.self, span, completion)
    }
    @discardableResult
    func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                  to object: O,
                                  _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                  mode: BindMode = .oneWay,
                                  mapper: @escaping (T) -> R = { $0 as! R },
                                  _ span: Span = .always,
                                  completion: ((T) -> ())? = nil) -> Disposable {
        bind(sourceKeyPath, to: object, objectKeyPath, mode: mode, mapper: mapper, span, completion: completion)
    }
    
    @discardableResult
    func bind<O: AnyObject, R>(to object: O,
                               _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                               mode: BindMode = .oneWay,
                               mapper: @escaping (BindingType) -> R = { $0 as! R },
                               _ span: Span = .always,
                               completion: ((BindingType) -> ())? = nil) -> Disposable {
        bind(\BindingType.self, to: object, objectKeyPath, mode: mode, mapper: mapper, span, completion: completion)
    }
    
    func bindOn<O:AnyObject, R>(_ object: O,
                                _ objectKeyPath: ReferenceWritableKeyPath<O, R>) -> BindableBuilder<BindingType, BindingType, O, R> {
        return bindOn(\BindingType.self, object, objectKeyPath)
    }
    
    var observeOn: ObservableBuilder<BindingType, BindingType> {
        return observeOn(\BindingType.self)
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
    
    private let lock = NSRecursiveLock()
    
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
    public var value:BindingType? {
        get {
            return immutable.currentValue
        }
    }
    
    public func update(_ newValue:BindingType) {
        lock.lock(); defer{lock.unlock()}
        immutable.currentValue = newValue
        immutable.observers.forEach{ $1(newValue) }
    }
    
    /// projectedValue from @propertyWrapper to easily access value from Bindable instance
    /// While mantaing exported value property for ImmutableBindable
    public var projectedValue: BindingType {
        get {
            /*
             * Note:
             * If you try to directly unwrap currentValue it will crash with Optional BindingType.
             * Contional casting on the other hand can have optional outcome with nil value in it.
             */
            return value as! BindingType
        }
        set {
            update(newValue)
        }
    }
    
    //MARK:- Builder methods
    public func observeOn<T>(_ sourceKeyPath: KeyPath<BindingType, T>) -> ObservableBuilder<BindingType, T> {
        return immutable.observeOn(sourceKeyPath)
    }
    
    public func bindOn<O:AnyObject, R>(_ object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, R>) -> BindableBuilder<BindingType, BindingType, O, R> {
        return bindOn(\BindingType.self, object, objectKeyPath)
    }
    
    public func bindOn<T, O:AnyObject, R>(_ sourceKeyPath: KeyPath<BindingType, T>, _ object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, R>) -> BindableBuilder<BindingType, T, O, R> {
        return immutable.bindOn(sourceKeyPath, object, objectKeyPath)
    }
    
    @discardableResult
    public func observe<T>(_ sourceKeyPath: KeyPath<BindingType, T>, _ span:Span = .always, _ completion: @escaping (T) -> ()) -> Disposable {
        return immutable.observe(sourceKeyPath, span, completion)
    }
    
    @discardableResult
    public func bind<O: AnyObject, T, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                         to object: O,
                                         _ objectKeyPath: ReferenceWritableKeyPath<O, R>,
                                         mode: BindMode = .oneWay,
                                         mapper: @escaping (T) -> R = { $0 as! R },
                                         _ span: Span = .always,
                                         completion: ((T) -> ())? = nil) -> Disposable {
        return immutable.bind(sourceKeyPath, to: object, objectKeyPath, mode: mode, mapper: mapper, span, completion: completion)
    }
    
}

public class ObservableBuilder<BindingType,T> {
    //MARK: Properties
    fileprivate var sourceKeyPath: KeyPath<BindingType, T>?
    fileprivate var span: Span = .always
    fileprivate weak var bindable: ImmutableBindable<BindingType>?
    
    required init(_ bindable: ImmutableBindable<BindingType>) {
        self.bindable = bindable
    }
    
    //MARK: span
    public var once: Self {
        self.span = .once
        return self
    }
    public var always: Self {
        self.span = .always
        return self
    }
    public func times(_ time:Int) -> Self {
        self.span = .times(time)
        return self
    }
    //MARK: Build
    @discardableResult
    public func done(_ handler: @escaping (T) -> ()) -> Disposable {
        return bindable!.observe(sourceKeyPath!,
                                 span,
                                 handler)
    }
    
}
public class BindableBuilder<BindingType,T, O:AnyObject, R>: ObservableBuilder<BindingType,T> {
    //MARK: Properties
    fileprivate var object: O?
    fileprivate var objectKeyPath: ReferenceWritableKeyPath<O, R>?
    fileprivate var mode: BindMode = .oneWay
    fileprivate var map:  ((T) -> R)?
    fileprivate var completion: ((T) -> ())? = nil
    
    required init(_ bindable: ImmutableBindable<BindingType>) {
        super.init(bindable)
    }
    
    //MARK: mode
    public var oneWay: Self {
        self.mode = .oneWay
        return self
    }
    public var towWay: Self {
        self.mode = .towWay
        return self
    }
    //MARK: map
    public func map(_ map: @escaping (T) -> R) -> Self {
        self.map = map
        return self
    }
    //MARK: Build
    @discardableResult
    public override func done(_ handler: ((T) -> ())? = nil) -> Disposable {
        self.completion = handler
        return bindable!.bind(sourceKeyPath!,
                              to: object!,
                              objectKeyPath!,
                              mode: mode,
                              mapper: map ?? { $0 as! R },
                              span,
                              completion: completion)
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
    
    private var sourceKeyPath: AnyKeyPath?
    
    //Current ImmutableBindable primaryKey used with DisposabkeBag
    lazy fileprivate var primaryKey: ObjectIdentifier = ObjectIdentifier(self)
    
    //MARK: Properties
    /// Current value
    public var value:BindingType? {
        get {
            return currentValue
        }
    }
    
    //MARK:- Builder methods
    
    public func observeOn<T>(_ sourceKeyPath: KeyPath<BindingType, T>) -> ObservableBuilder<BindingType, T> {
        let builder = ObservableBuilder<BindingType, T>(self)
        builder.sourceKeyPath = sourceKeyPath
        return builder
    }
    
    public func bindOn<O:AnyObject, R>(_ object: O,
                                       _ objectKeyPath: ReferenceWritableKeyPath<O, R>) -> BindableBuilder<BindingType, BindingType, O, R> {
        return bindOn(\BindingType.self, object, objectKeyPath)
    }
    
    public func bindOn<T, O:AnyObject, R>(_ sourceKeyPath: KeyPath<BindingType, T>,
                                          _ object: O, _ objectKeyPath: ReferenceWritableKeyPath<O, R>) -> BindableBuilder<BindingType, T, O, R> {
        let builder = BindableBuilder<BindingType, T, O, R>(self)
        builder.sourceKeyPath = sourceKeyPath
        builder.object = object
        builder.objectKeyPath = objectKeyPath
        return builder
    }
    //MARK: Methods
    
    /// Main init for BindableImmutable<BindingType>
    /// - Parameter value: initial value wrapped on this bindable object, default value = nil
    public init(_ value: BindingType? = nil) {
        currentValue = value
    }
    
    /// cleaning before object deinit
    deinit {
        DisposableBag.dispose(primaryKey: primaryKey)
        NotificationCenter.default.removeObserver(self)
    }
    
    @discardableResult
    public func observe<T>(_ sourceKeyPath: KeyPath<BindingType, T>,
                           _ span: Span = .always,
                           _ completion: @escaping (T) -> ()) -> Disposable {
        currentValue.map { completion($0[keyPath: sourceKeyPath]) }
        let secondaryKey = UUID().uuidString
        let disposable = DisposableUnit(primaryKey, secondaryKey) { [weak self] in
            self?.observers.removeValue(forKey: secondaryKey)
        }
        var currentSpan = span
        observers[secondaryKey] = { [weak disposable] in
            completion($0[keyPath: sourceKeyPath])
            if currentSpan.tik() { disposable?.dispose() }
        }
        return disposable
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
                                         _ span: Span = .always,
                                         completion: ((T) -> ())? = nil) -> Disposable {
        
        if mode == .towWay {
            addTowWayBinding(object, objectKeyPath)
        }
        return addObserver(for: object, objectKeyPath, mode, span) { [weak object] observed in
            guard let object = object else { return }
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
                                              _ mode: BindMode = .oneWay,
                                              _ span: Span = .always,
                                              completion: @escaping (BindingType) -> Void) -> Disposable {
        let secondaryKey = getObserverHash(object, objectKeyPath)
        //Dipose previous binding from object/objectKeyPath pair
        DisposableBag.dispose(secondaryKey: secondaryKey)
        //Invoke completion for initial value (if any)
        currentValue.map { completion($0) }
        let disposable =  DisposableUnit(primaryKey, secondaryKey) { [weak self, weak object, weak objectKeyPath] in
            guard let object = object, let objectKeyPath = objectKeyPath else { return }
            self?.unbind(from: object, objectKeyPath, mode: mode)
        }
        var currentSpan = span
        observers[secondaryKey] = { [weak disposable] in
            completion($0)
            if currentSpan.tik() { disposable?.dispose() }
        }
        return disposable
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
        }else if object is UITextView { //UITextView case since it is not part of UIControl
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
        }else if object is UITextView { //UITextView case since it is not part of UIControl
            NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
        }
        keyPath = nil
    }
}
