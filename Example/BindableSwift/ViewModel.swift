//
//  ViewModel.swift
//  BindableExample
//
//  Created by Hossam Sherif on 12/12/20.
//

import Foundation
import BindableSwift
enum MyError: Error {
    var code: Int {
        switch self {
        case .boom:
            return 100
        case .custom(let code, _):
            return code
        }
    }
    var description:String {
        self.localizedDescription
    }
    case boom
    case custom(code: Int = 100, description:String = "booming")
}
typealias EventResult<T> = EventResultBase<T,Error>
typealias EventResultBase<T, E:Error> = Eventable<Result<T, E>>

struct MyStruct {
    var name:String
    var active:Bool
}

protocol ViewModelProtocol: class {
    var input: Event.Immutable { get }
    var input2: Event.Immutable { get }
    var input3: Eventable<String>.Immutable { get }
    var input4: Eventable<()>.Immutable { get }
    var input5: Eventable<(name: String, active: Bool)>.Immutable { get }
    var input6: EventResult<Bool>.Immutable { get }
    var input7: EventResult<Void>.Immutable { get }
    
    
    var shouldGoToVC: Bindable<Bool>.Immutable { get }
    
    var isLoading: Bindable<Bool>.Immutable { get }
    var data: Bindable<[CellViewModelProtocol]>.Immutable { get }
    var myStruct: Bindable<MyStruct>.Immutable { get }
    var viewDidLoad: Event.Immutable { get }
    
    
    var numberOnlyValidator: Event.Immutable { get }
    var name: Bindable<String>.Immutable { get }
    var strTest: Bindable<String>.Immutable { get }
}

class ViewModel: ViewModelProtocol {
    
    let input: Event.Immutable = Event {
        print("hello")
    }.immutable
    @Event var input2
    var i:Int  = 0
    @Eventable<String> var input3
    lazy var input4 = Eventable<()>({ [weak self] stateHandler in
        guard let self = self else { return }
        self.printHello(4)
        self.$shouldGoToVC = true
        stateHandler(())
    }).immutable
    @Eventable<(name: String,active: Bool)> var input5
    @EventResult<Bool> var input6
    lazy var input7 = EventResult<()>({ [weak self] stateHandler in
        guard let self = self else { return }
        self.printHello(4)
        self.$shouldGoToVC = true
        stateHandler(.success(()))
    }).immutable
    lazy var viewDidLoad = Event { [weak self] in
        guard let self = self else { return }
        self.viewDidLoadHanlding()
    }.immutable
    
    @Bindable<Bool>(false) var shouldGoToVC
    @Bindable<Bool>(false) var isLoading
    
    @Bindable<[CellViewModelProtocol]> var data
    @Bindable<MyStruct> var myStruct
    
    
    
    @Event var numberOnlyValidator
    @Bindable<String> var name
    @Bindable<String> var strTest
    
    init() {
        $data = generateData()
//        $name = "first"
        $myStruct = MyStruct(name: "ABC", active: true)
        $input2 = {
            print("hello2")
        }
        $input6 = { stateHandler in
            stateHandler(.success(true))
//            stateHandler(.failure(NSError(domain: "error.domain", code: 101, userInfo: nil)))
//            stateHandler(.failure(MyError.custom(code: 200, description: "custom")))
        }
        let input3State = self.input3.asBindable
        $input3 = { [weak input3State] stateHandler in
            var value = input3State?.value ?? ""
            if value.last == "$" {
                value.removeLast()
            }
            stateHandler(value)
        }
        $numberOnlyValidator = { [weak self] in
            guard let self = self, let lastChar = self.$name.last else { return }
            if !lastChar.isNumber {
                print(self.$name.removeLast())
            }
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
    
    func viewDidLoadHanlding() {
        $isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            self.$isLoading = false
            self.$name = "Hossam Sherif"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
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
        _title.update(title)
    }
    init(title: Bindable<String>) {
        _title = title
    }
}
