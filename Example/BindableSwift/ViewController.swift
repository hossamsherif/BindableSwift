//
//  ViewController.swift
//  BindableExample
//
//  Created by Hossam Sherif on 12/12/20.
//

import UIKit
import BindableSwift

protocol UserDefaultsManagerProtocol: class {
    var appVersion: Bindable<String?> { get set }
    var isFirstTime: Bindable<Bool> { get set }
}

class UserDefaultsManager: UserDefaultsManagerProtocol {
    
    struct  UserDefaultsKeys {
        static let appVersion = "UserDefaultsKeysAppVersion"
        static let firstTime = "UserDefaultsKeysFirstTime"
    }
    
    // MARK:- Singleton
    
    static let shared:UserDefaultsManagerProtocol = UserDefaultsManager()
    
    // MARK: Properties
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        appVersion.bind(to: self, \.appVersionValue)
        isFirstTime.bind(to: self, \.isFirstTimeValue)
    }
    
    // MARK:- Properties
    
    lazy var appVersion = Bindable<String?>(appVersionValue)
    private var appVersionValue: String? {
        get {
            if let appVersion = userDefaults.string(forKey: UserDefaultsKeys.appVersion) {
                return appVersion
            } else {
                let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                return version
            }
        }
        set {
            userDefaults.set(newValue, forKey:UserDefaultsKeys.appVersion)
        }
    }
    
    lazy var isFirstTime = Bindable<Bool>(isFirstTimeValue)
    private var isFirstTimeValue: Bool {
        set {
            userDefaults.set(newValue, forKey: UserDefaultsKeys.firstTime)
        }
        get {
            guard userDefaults.object(forKey: UserDefaultsKeys.firstTime) != nil else {
                return true
            }
            return userDefaults.bool(forKey: UserDefaultsKeys.firstTime)
        }
    }
}


class ViewController: UIViewController {
    
    var myView:MyView!
    
    var viewModel:ViewModelProtocol!
    
    //    var isLoading:Bool = false {
    //        didSet {
    //            if isLoading {
    //                loader.startAnimating()
    //            }
    //            else {
    //
    //                loader.stopAnimating()
    //            }
    //            loader.isHidden = !isLoading
    //        }
    //    }
    
    var data: [CellViewModelProtocol] {
        return viewModel.data.value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindVM()
//        let appversion = UserDefaultsManager.shared.appVersion.value
        viewModel.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bindUserDefaults()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DisposableBag.dispose(self)
    }
    
    func setupView() {
        myView = MyView(frame: view.bounds)
        view.addSubview(myView)
        myView.matchParentConstraint()
        myView.tableView.dataSource = self
        myView.tableView.rowHeight = 44.0
    }
    
    class func create(viewModel:ViewModelProtocol = ViewModel()) -> UIViewController {
        let viewController = ViewController()
        viewController.viewModel = viewModel
        return viewController
    }
    
    func bindUserDefaults() {
        DisposableBag.container(self, [
            UserDefaultsManager.shared.appVersion.bind(\String.self, to: self, \.title, mapper: {
                "Bindable Example \($0 ?? "")"
            })
            
        ])
        //...
        DisposableBag.container(self, [
            UserDefaultsManager.shared.isFirstTime.bind(\Bool.self, to: myView.switchControl, \.isOn)
        ])
    }
    
    func bindVM() {
        
//        if UserDefaultsManager.shared.isFirstTime.value {
//            UserDefaultsManager.shared.isFirstTime.value = false
//        }
        
        viewModel.isLoading.bind(to: myView.loader, \.isHidden, mapper: { !$0 }, completion: { [weak self] isLoading in
            isLoading ? self?.myView.loader.startAnimating() : self?.myView.loader.stopAnimating()
        })
        viewModel.name.bind(to: myView.textField, \.text, mode: .towWay, completion:  { newValue in
            print(newValue)
        })
        viewModel.name.bind(to: myView.label, \.text, mapper:  { $0.isEmpty ? "" : "Mr. \($0)" })
        
        viewModel.name.observe(\String.self) { [weak self] in
            self?.myView.switchControl.setOn($0.isEmpty, animated: true)
        }
//        viewModel.isLoading.bind(to: myView, \.myEnum, mapper: { $0 ? .x : .y }) { [weak self] in
//            print($0, self?.myView.myEnum ?? "-")
//        }
        
        viewModel.myStruct.bind(\.name, to: myView.label, \.text, mapper: { $0.description })
                viewModel.name.bind(\String.self, to: myView.switchControl, \.isOn, mapper:  { $0.isEmpty })
        
                viewModel.name.bind(\String.self, to: myView.switchControl, \.isOn, mapper:  { [weak self] _ in
                    return self?.myView.switchControl.isOn ?? false
                }, completion:{ [weak self] in
                    self?.myView.switchControl.setOn($0.isEmpty, animated: true)
                })
        
        viewModel.data.observe { [weak self] _ in
            self?.myView.tableView.reloadData()
        }
//
        viewModel
            .input6
            .on(myView.button, for: .touchUpInside)
            .asBindable
            .observe { [weak self] result in
                do {
                    let x = try result.get()
                    print("vc eventStae: \(x)")
                    self?.navigationController?.pushViewController(ViewController.create(), animated: true)
                } catch MyError.boom {
                    print(MyError.boom)
                } catch MyError.custom(let code, let description){
                    print(code, description)
                } catch {
                    print("default")
                }

        }
        viewModel.input.signal()
        viewModel.input3().observe { (int) in
            print(int)
        }
        
        viewModel
            .input
            .on(myView.button, for: .touchUpInside)
        
//        viewModel.shouldGoToVC.observe(\Bool.self) { [weak self] in
//            $0 ? self?.navigationController?.pushViewController(ViewController.create(), animated: true) : ()
//        }
    }
}

//MARK:- UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyCell.stringType(), for: indexPath) as! MyCell
        let cellVM = data[indexPath.row]
        cell.viewModel = cellVM
        cell.selectionStyle = .none
        return cell
    }
}
enum MyEnum {
    case x
    case y
}
//MARK:- MyView
class MyView: UIView {
    
    var myEnum:MyEnum = .x
    
    let button = { () -> UIButton in
        let button = UIButton(type: .system)
        button.setTitle("Let's go", for: .normal)
        return button
    }()
    let loader = UIActivityIndicatorView()
    let label = { () -> UILabel in
        let label = UILabel()
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 21.0).isActive = true
        return label
    }()
    let textField = { () -> UITextField in
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.textContentType = .name
        return textField
    }()
    let switchControl = UISwitch()
    let tableView = { () -> UITableView in
        let tableView = UITableView()
        tableView.register(MyCell.self, forCellReuseIdentifier: MyCell.stringType())
        return tableView
    }()
    let stackView = { () -> UIStackView in
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 30.0
        return stackView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        stackView.addArrangedSubview(loader)
        stackView.addArrangedSubview(button)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(switchControl)
        stackView.addArrangedSubview(tableView)
        addSubview(stackView)
        stackView.matchParentConstraint(margin: UIEdgeInsets(top: 30, left: 15, bottom: 0, right: -15))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//MARK:- MyCell
class MyCell: UITableViewCell {
    
    var titleLabel = UILabel()
    weak var viewModel:CellViewModelProtocol? {
        didSet {
            bindVM()
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        titleLabel.matchParentConstraint(margin: UIEdgeInsets(top: 10, left: 15, bottom: -10, right: -15))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindVM() {
        viewModel?.title.bind(\String.self, to: titleLabel, \.text)
    }
}

//MARK:- Utility extensions

extension NSObjectProtocol {
    static func stringType() -> String {
        return "\(Self.self)"
    }
}

extension UIView {
    func matchParentConstraint(margin:UIEdgeInsets = UIEdgeInsets.zero) {
        guard let superview = superview?.safeAreaLayoutGuide else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: margin.top),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: margin.bottom),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: margin.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: margin.right)
        ])
    }
}
