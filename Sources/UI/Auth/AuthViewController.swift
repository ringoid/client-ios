//
//  AuthViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class AuthViewController: BaseViewController
{
    var input: AuthVMInput!
    
    fileprivate var viewModel: AuthViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var maleContainerView: UIView!
    @IBOutlet fileprivate weak var femaleContainerView: UIView!
    @IBOutlet fileprivate weak var maleBtn: UIButton!
    @IBOutlet fileprivate weak var femaleBtn: UIButton!
    @IBOutlet fileprivate weak var birthYearContainerView: UIView!
    @IBOutlet fileprivate weak var birthYearTextField: UITextField!
    @IBOutlet fileprivate weak var registerBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.setupUI()
        self.setupBindings()
        self.birthYearTextField.becomeFirstResponder()
        self.viewModel?.enableFirstTimeFlow()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    @IBAction func onRegister()
    {
        self.viewModel?.register().subscribe(onError: { [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        }).disposed(by: self.disposeBag)
    }
        
    // MARK: -
    
    fileprivate func setupUI()
    {
        self.birthYearContainerView.layer.borderWidth = 1.0
        self.birthYearContainerView.layer.borderColor = UIColor(red: 73.0 / 255.0, green: 73.0 / 255.0, blue: 73.0 / 255.0, alpha: 1.0).cgColor
        self.maleContainerView.layer.borderColor = UIColor(red: 100.0 / 255.0, green: 170.0 / 255.0, blue: 9.0 / 255.0, alpha: 1.0).cgColor
        self.femaleContainerView.layer.borderColor = UIColor(red: 100.0 / 255.0, green: 170.0 / 255.0, blue: 9.0 / 255.0, alpha: 1.0).cgColor
    }
    
    fileprivate func setupBindings()
    {
        let viewModel = AuthViewModel(self.input)
        self.viewModel = viewModel
            
        self.birthYearTextField.rx.text.map({ text -> Int? in
            guard let text = text else { return nil }
            
            return Int(text)
        }).bind(to: viewModel.birthYear).disposed(by: self.disposeBag)
        
        self.maleBtn.rx.controlEvent(.touchUpInside).map({ _ -> Sex in
            return .male
        }).bind(to: viewModel.sex).disposed(by: self.disposeBag)
        
        self.femaleBtn.rx.controlEvent(.touchUpInside).map({ _ -> Sex in
            return .female
        }).bind(to: viewModel.sex).disposed(by: self.disposeBag)
        
        viewModel.sex.asObservable().subscribe(onNext: { [weak self] sex in
            self?.updateRegistrationState()
            self?.updateSexState(sex)
        }).disposed(by: self.disposeBag)
        
        viewModel.birthYear.asObservable().subscribe(onNext: { [weak self] _ in
            self?.updateRegistrationState()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateRegistrationState()
    {
        let isValidated = self.viewModel?.sex.value != nil &&
        self.viewModel?.birthYear.value != nil
        
        self.registerBtn.alpha = isValidated ? 1.0 : 0.5
        self.registerBtn.isEnabled = isValidated
    }
    
    fileprivate func updateSexState(_ sex: Sex?)
    {
        guard let sex = sex else { return }
        
        switch sex {
        case .male:
            self.maleContainerView.layer.borderWidth = 1.0
            self.femaleContainerView.layer.borderWidth = 0.0
            break
        case .female:
            self.femaleContainerView.layer.borderWidth = 1.0
            self.maleContainerView.layer.borderWidth = 0.0
        }
    }
}
