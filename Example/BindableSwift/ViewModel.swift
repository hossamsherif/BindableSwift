//
//  ViewModel.swift
//  BindableExample
//
//  Created by Hossam Sherif on 12/12/20.
//

import Foundation
import BindableSwift


struct MyStruct {
    var name:String
    var active:Bool
}

protocol ViewModelProtocol: class {
    var input: Event.Immutable { get }
    var input2: Event.Immutable { get }
    var input3: Eventable<Int>.Immutable { get }
    var input4: Event.Immutable { get }
    var input5: Eventable<(name: String, active: Bool)>.Immutable { get }
    
    
    var shouldGoToVC: Bindable<Bool>.Immutable { get }
    var name: Bindable<String>.Immutable { get }
    var isLoading: Bindable<Bool>.Immutable { get }
    var data: Bindable<[CellViewModelProtocol]>.Immutable { get }
    var myStruct: Bindable<MyStruct>.Immutable { get }
    func viewDidLoad()
}

class ViewModel: ViewModelProtocol {
    
    let input: Event.Immutable = Event { completion in
        print("hello")
        completion()
    }.immutable
    @Event var input2
    lazy var input3 = Eventable<Int> { [weak self] completion in
        self?.printHello(3)
        completion(3)
    }.immutable
    lazy var input4 = Event { [weak self] _ in
        self?.printHello(4)
        self?.$shouldGoToVC = true
    }.immutable
    @Eventable<(name: String,active: Bool)> var input5
    
    @Bindable<Bool>(false) var shouldGoToVC
    @Bindable<Bool>(false) var isLoading
    @Bindable<String> var name
    @Bindable<[CellViewModelProtocol]> var data
    @Bindable<MyStruct> var myStruct
    
    init() {
        $data = generateData()
        $myStruct = MyStruct(name: "ABC", active: true)
        $input2 = { completion in
            print("hello2")
            completion()
        }
    }
    
    func generateData() -> [CellViewModelProtocol] {
        let names:[String] = ["Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek","Essam", "Ehab", "Tarek"]
        var data = [CellViewModelProtocol]()
        for str in names {
            data.append(CellViewMode(title: "\(str) \(Int.random(in: 0...1000))"))
        }
        data.insert(CellViewMode(title: _name), at: 0)
        return data
    }
    
    func viewDidLoad() {
        $isLoading = true
        MainThread(self, after: .now() + 3.0) { (self) in
            self.$isLoading = false
            self.$name = "Hossam Sherif"
        }

        MainThread(self, after: .now() + 5.0) { (self) in
            self.$data.insert(CellViewMode(title: "7amada"), at: 0)
            self.$myStruct.name = "XYZ"
        }
    }
    
    func printHello(_ int:Int) {
        print("hello\(int)")
    }
    
    func printHello3() {
        print("hello3")
    }
    
}

protocol CellViewModelProtocol: class {
    var title: ImmutableBindable<String> { get }
}

class CellViewMode: CellViewModelProtocol {
    @Bindable<String> var title
    init(title:String) {
        _title.value = title
    }
    init(title: Bindable<String>) {
        _title = title
    }
}

public func MainThread<`self`: AnyObject>(_ on:`self`, _ block:@escaping (`self`)->()) {
    DispatchQueue.main.async { [weak on] in
        guard let on = on else { return }
        block(on)
    }
}

public func MainThread<self: AnyObject>(_ `self`: `self`, after: DispatchWallTime, _ block:@escaping (`self`)->()) {
    DispatchQueue.main.asyncAfter(wallDeadline: after)  { [weak self] in
        guard let self = self else { return }
        block(self)
    }
}
