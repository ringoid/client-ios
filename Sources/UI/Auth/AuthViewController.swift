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

class AuthViewController: UIViewController
{
    var input: AuthVMInput!
    
    fileprivate var viewModel: AuthViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var maleBtn: UIButton!
    @IBOutlet fileprivate weak var femaleBtn: UIButton!
    @IBOutlet fileprivate weak var birthYearTextField: UITextField!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.setupBindings()
    }
    
    @IBAction func onRegister()
    {
        self.viewModel?.register().subscribe(onError: { [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
        }).disposed(by: self.disposeBag)
    }

    // MARK: -
    
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
    }
}
