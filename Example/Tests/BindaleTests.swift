import XCTest
@testable import BindableSwift



class BindaleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //MARK:- Test .bind oneWay
    
    func testBindOneWayWithDefaultParams () {
        let provider = BindableProvider<String>()
        let textStr = Binder<String>("")
        provider.sut.bind(\String.self, to: textStr, \.value)
        let testStr = "abc"
        provider.$sut = testStr
        XCTAssertEqual(textStr.value, testStr)
    }
    
    func testBindOneWayWithoutModeDefaultParams () {
        let provider = BindableProvider<String>()
        let textStr = Binder("")
        provider.sut.bind(\String.self, to: textStr, \.value, mode: .oneWay)
        let testStr = "abc"
        provider.$sut = testStr
        XCTAssertEqual(textStr.value, testStr)
    }
    
    func testBindOneWayType<T: Equatable>(initValue: T, testValue: T) {
        let provider = BindableProvider<T>()
        let target = Binder(initValue)
        provider.sut.bind(\T.self, to: target, \.value, mode: .oneWay)
        provider.$sut = testValue
        XCTAssertEqual(target.value, testValue)
    }
    
    
    func testBindOneWayBool () {
        testBindOneWayType(initValue: false, testValue: true)
    }
    
    func testBindOneWayInt () {
        testBindOneWayType(initValue: 0, testValue: 1)
    }
    
    func testBindOneWayDouble () {
        testBindOneWayType(initValue: 0.0, testValue: 1.0)
    }
    
    func testBindOneWayFloat () {
        testBindOneWayType(initValue: Float(0.0), testValue: Float(1.0))
    }
    
    func testBindOneWayCGFloat () {
        testBindOneWayType(initValue: CGFloat(0.0), testValue: CGFloat(1.0))
    }
    
    func testBindOneWayString () {
        testBindOneWayType(initValue: "", testValue: "test")
    }
    
    func testBindOneWayArrayType () {
        testBindOneWayType(initValue: [String](), testValue: ["test"])
    }
    
    func testBindOneWayArray () {
        let provider = BindableProvider<[String]>(value: [])
        let target = Binder([String]())
        provider.sut.bind(\[String].self, to: target, \.value, mode: .oneWay)
        let testValue = "test"
        provider.$sut.append(testValue)
        XCTAssertEqual(target.value.first, testValue)
    }
    
    func testBindOneWayDictionaryType () {
        testBindOneWayType(initValue: [String:Bool](), testValue: ["test":true])
    }
    
    func testBindOneWayDictionary () {
        let provider = BindableProvider<[String:Bool]>(value: [:])
        let target = Binder([String:Bool]())
        provider.sut.bind(\[String:Bool].self, to: target, \.value, mode: .oneWay)
        let testValue = true
        provider.$sut["test"] = true
        XCTAssertEqual(target.value["test"], testValue)
    }
    
    func testBindOneWayEnum () {
        testBindOneWayType(initValue: MyTestEnum.x, testValue: MyTestEnum.y)
    }
    
    func testBindOneWayStructType () {
        testBindOneWayType(initValue: MyTestStruct(x: 0), testValue: MyTestStruct(x: 1))
    }
    
    func testBindOneWayStruct () {
        let provider = BindableProvider<MyTestStruct>(value: MyTestStruct(x: 0))
        let target = Binder(MyTestStruct(x: 0))
        provider.sut.bind(\.x, to: target, \.value.x, mode: .oneWay)
        let testValue = 1
        provider.$sut.x = 1
        XCTAssertEqual(target.value.x, testValue)
    }
    
    func testBindOneWayUILabel() {
        let provider = BindableProvider<String>(value: "")
        let target = UILabel()
        provider.sut.bind(\String.self, to: target, \.text)
        provider.$sut = "test"
        XCTAssertEqual(target.text, provider.$sut)
    }
    
    func testBindOneWayOptional () {
        //Bool?
        testBindOneWayType(initValue: nil, testValue: true)
        testBindOneWayType(initValue: true, testValue: nil)
        //Int?
        testBindOneWayType(initValue: nil, testValue: 0)
        testBindOneWayType(initValue: 0, testValue: nil)
        //Double?
        testBindOneWayType(initValue: nil, testValue: 0.0)
        testBindOneWayType(initValue: 0.0, testValue: nil)
        //Float?
        testBindOneWayType(initValue: nil, testValue: Float(0.0))
        testBindOneWayType(initValue: Float(0.0), testValue: nil)
        //CGFloat?
        testBindOneWayType(initValue: nil, testValue: CGFloat(0.0))
        testBindOneWayType(initValue: CGFloat(0.0), testValue: nil)
        //String?
        testBindOneWayType(initValue: nil, testValue: "test")
        testBindOneWayType(initValue: "test", testValue: nil)
        //Enum?
        testBindOneWayType(initValue: nil, testValue: MyTestEnum.x)
        testBindOneWayType(initValue: MyTestEnum.x, testValue: nil)
        //Struct?
        testBindOneWayType(initValue: MyTestStruct(), testValue: nil)
        testBindOneWayType(initValue: nil, testValue: MyTestStruct())
        //Array?
        testBindOneWayType(initValue: ["test"], testValue: nil)
        testBindOneWayType(initValue: nil, testValue: ["test"])
        //Dictionary?
        testBindOneWayType(initValue: ["test": true], testValue: nil)
        testBindOneWayType(initValue: nil, testValue: ["test": true])
    }
    
    //MARK:- Test .bind twoWay
    
    func testBindTowWayUITextField() {
        let provider = BindableProvider<String>(value: "")
        let target = UITextField()
        provider.sut.bind(\String.self, to: target, \.text, mode: .towWay)
        provider.$sut = "test"
        XCTAssertEqual(target.text, provider.$sut)
        target.text = "edit test"
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(provider.$sut, target.text)
    }
    
    func testBindTowWayUISwitch() {
        let provider = BindableProvider<Bool>(value: false)
        let target = UISwitch()
        provider.sut.bind(\Bool.self, to: target, \.isOn, mode: .towWay)
        provider.$sut = true
        XCTAssertEqual(target.isOn, provider.$sut)
        target.isOn = false
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(provider.$sut, target.isOn)
    }
    
    func testBindTowWayUISegmentedControl() {
        let provider = BindableProvider<Int>(value: 0)
        let target = UISegmentedControl(items: ["A", "B"])
        provider.sut.bind(\Int.self, to: target, \.selectedSegmentIndex, mode: .towWay)
        provider.$sut = 1
        XCTAssertEqual(target.selectedSegmentIndex, provider.$sut)
        target.selectedSegmentIndex = 0
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(provider.$sut, target.selectedSegmentIndex)
    }
    
    func testBindTowWayUIPageControl() {
        let provider = BindableProvider<Int>(value: 0)
        let target = UIPageControl()
        target.numberOfPages = 2
        provider.sut.bind(\Int.self, to: target, \.currentPage, mode: .towWay)
        provider.$sut = 1
        XCTAssertEqual(target.currentPage, provider.$sut)
        target.currentPage = 0
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(provider.$sut, target.currentPage)
    }
    
    func testBindTowWayUISlider() {
        let provider = BindableProvider<Float>(value: 0)
        let target = UISlider()
        target.minimumValue = 0.0
        target.maximumValue = 100.0
        provider.sut.bind(\Float.self, to: target, \.value, mode: .towWay)
        provider.$sut = Float(50.0)
        XCTAssertEqual(target.value, provider.$sut)
        target.value = 100.0
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(provider.$sut, target.value)
    }
    
    func testBindTowWayUIDatePicker() {
        let provider = BindableProvider<Date?>()
        let target = UIDatePicker()
        target.datePickerMode = .date
        provider.sut.bind(\Date.self, to: target, \.date, mode: .towWay)
        provider.$sut = Date()
        XCTAssertEqual(target.date, provider.$sut)
        target.date = Date(timeInterval: 24*60*60, since: Date())
        target.sendActions(for: .editingChanged)
        XCTAssertEqual(provider.$sut, target.date)
    }
    
    func testBindTowWayUITextView() {
        let provider = BindableProvider<String>(value: "")
        let target = UITextView()
        provider.sut.bind(\String.self, to: target, \.text, mode: .towWay)
        provider.$sut = "test"
        XCTAssertEqual(target.text, provider.$sut)
        target.text = "edit test"
        //Simulate textView text did change from keyboard
        NotificationCenter.default.post(name: UITextView.textDidChangeNotification, object: target)
        XCTAssertEqual(provider.$sut, target.text)
    }
    
    
}

struct MyTestStruct: Hashable {
    var x:Int = 0
}

enum MyTestEnum {
    case x
    case y
}

protocol BindableProviderProtocol {
    associatedtype T
    var sut: Bindable<T>.Immutable { get }
}

class BindableProvider<T>: BindableProviderProtocol {
    @Bindable<T> var sut
    init() { }
    init(value: T) {
        $sut = value
    }
}

class Binder<T> {
    var value: T
    init(_ value: T) {
        self.value = value
    }
}
