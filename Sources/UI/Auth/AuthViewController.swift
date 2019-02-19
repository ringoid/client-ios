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
    @IBOutlet fileprivate weak var themeBtn: UIButton!
    @IBOutlet fileprivate weak var termsPolicyTextView: UITextView!
    @IBOutlet fileprivate weak var authActivityView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var birthErrorView: UIView!
    @IBOutlet fileprivate weak var birthValidView: UIView!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        #if STAGE
        self.themeBtn.isHidden = false
        #else
        self.themeBtn.isHidden = true
        #endif
        
        self.authActivityView.stopAnimating()
        
        let linkColor = UIColor(red: 73.0 / 255.0, green: 183.0 / 255.0, blue: 70.0 / 255.0, alpha: 1.0)
        self.termsPolicyTextView.linkTextAttributes = [
            .foregroundColor: linkColor
        ]
        
        self.setupUI()
        self.setupBindings()
        self.birthYearTextField.delegate = self
        self.birthYearTextField.becomeFirstResponder()
        self.viewModel?.enableFirstTimeFlow()
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
        
        let theme = ThemeManager.shared.theme.value
        let themeImageName = theme == .dark ? "auth_theme_btn_night" : "auth_theme_btn_day"
        self.themeBtn.setImage(UIImage(named: themeImageName), for: .normal)
        
        self.birthYearTextField.textColor = ContentColor().uiColor()
        self.birthYearTextField.keyboardAppearance = theme == .dark ? .dark : .light
        self.birthYearTextField.resignFirstResponder()
        self.birthYearTextField.becomeFirstResponder()
        
        self.updatePlaceholder()
        self.updateTermsPolicy()
    }
    
    override func updateLocale()
    {
        self.updatePlaceholder()
        self.updateTermsPolicy()
    }
    
    @IBAction func onRegister()
    {
        self.authActivityView.startAnimating()
        self.registerBtn.isHidden = true
        self.viewModel?.register().subscribe(
            onError: { [weak self] error in
            guard let `self` = self else { return }
            
            showError(error, vc: self)
            }, onCompleted: { [weak self] in
                self?.authActivityView.stopAnimating()
                self?.registerBtn.isHidden = false
        }).disposed(by: self.disposeBag)
    }
    
    @IBAction func onThemeChange()
    {
        self.viewModel?.switchTheme()
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
        let isDateValid = self.validateBirthYear()
        let isValidated = self.viewModel?.sex.value != nil && isDateValid
        
        if self.birthYearTextField.text?.count == 0 {
            self.birthYearContainerView.layer.borderColor = UIColor(red: 73.0 / 255.0, green: 73.0 / 255.0, blue: 73.0 / 255.0, alpha: 1.0).cgColor
            self.birthErrorView.isHidden = true
            self.birthValidView.isHidden = true
        } else {
            let validColor = UIColor(red: 100.0 / 255.0, green: 170.0 / 255.0, blue: 9.0 / 255.0, alpha: 1.0).cgColor
            let invalidColor = UIColor(red: 1.0, green: 152.0 / 255.0, blue: 0.0, alpha: 1.0).cgColor
            self.birthYearContainerView.layer.borderColor = isDateValid ? validColor : invalidColor
            self.birthErrorView.isHidden = isDateValid
            self.birthValidView.isHidden = !isDateValid
        }
        
        self.registerBtn.alpha = isValidated ? 1.0 : 0.5
        self.registerBtn.isEnabled = isValidated
    }
    
    fileprivate func validateBirthYear() -> Bool
    {
        guard let birthYear = self.viewModel?.birthYear.value else { return false }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let diff = currentYear - birthYear
        
        return diff >= 18 && diff <= 70
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
    
    fileprivate func updatePlaceholder()
    {
        self.birthYearTextField.attributedPlaceholder = NSAttributedString(string: "AUTH_YOB".localized(), attributes: [
            .foregroundColor: ContentColor().uiColor(),
            .font: UIFont.systemFont(ofSize: 17.0, weight: .light)
            ])
    }
    
    fileprivate func updateTermsPolicy()
    {
        let attributedText = "AUTH_TERMS_AND_POLICY".localizedWithAttributes(mainStringAttributes: [.foregroundColor: SecondContentColor().uiColor()], markers: [
            LocalizationAttributeMarker(marker: "$terms$", localizationKey: "AUTH_TERMS_OF_SERVICE", attributes: [
                .link: AppConfig.termsUrl
                ]),
            LocalizationAttributeMarker(marker: "$policy$", localizationKey: "AUTH_PRIVACY_POLICY", attributes: [
                .link: AppConfig.policyUrl
                ]),
            ])
        
        self.termsPolicyTextView.attributedText = attributedText
    }
}

extension AuthViewController: UITextViewDelegate
{
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool
    {
        UIApplication.shared.open(URL, options: [:], completionHandler: nil)
        
        return false
    }
}

extension AuthViewController: UITextFieldDelegate
{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        guard string != "" else { return true } // always allowing backspaces
        guard let text = textField.text else { return true }
        
        var dateText: NSString = text as NSString
        dateText = dateText.replacingCharacters(in: range, with: string) as NSString
        
        return dateText.length <= 4
    }
}
