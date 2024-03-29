//
//  SettingsProfileViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsProfileViewController: BaseViewController
{
    var input: SettingsProfileVMInput!
    var isModal: Bool = false
    
    fileprivate var viewModel: SettingsProfileViewModel?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        let openingCount = UserDefaults.standard.integer(forKey: "settings_profile_fields_opened")
        UserDefaults.standard.set(openingCount + 1, forKey:"settings_profile_fields_opened")
        
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 320.0, right: 0.0)
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onHideInput))
        recognizer.delegate = self
        self.view.addGestureRecognizer(recognizer)
        
        self.setupViewModel()
        self.tableView.reloadData()
    }
    
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        let darkThemeSeparatorColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        
        self.tableView.separatorColor = (theme == .dark) ? darkThemeSeparatorColor : .lightGray
        self.view.backgroundColor = BackgroundColor().uiColor()        
        self.backBtn.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_profile".localized()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        // Waiting 0.5 sec for local DB update
        let profileManager = self.input.profileManager
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            profileManager.updateProfile()
        }
        
        if self.isModal {
            ModalUIManager.shared.hide(animated: true)
            
            if UIManager.shared.discoverAddPhotoModeEnabled.value {
                UIManager.shared.discoverAddPhotoModeEnabled.accept(false)
                self.input.navigationManager.mainItem.accept(.search)
            }
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onHideInput()
    {
        UIApplication.shared.sendAction(#selector(UIView.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: -
    
    fileprivate func setupViewModel()
    {
        self.viewModel = SettingsProfileViewModel(self.input)
    }
}

extension SettingsProfileViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel?.configuration.settingsFields.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        // Suggest
//        if let count = self.viewModel?.configuration.settingsFields.count, indexPath.row == count {
//            guard let cell = tableView.dequeueReusableCell(withIdentifier: "profile_suggest_cell") as? SettingsProfileFieldsSuggest else { return UITableViewCell() }
//
//            return cell
//        }
        
        // Fields
        guard let field = self.viewModel?.configuration.settingsFields[indexPath.row] else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: field.cellIdentifier) as? SettingsProfileFieldCell else { return UITableViewCell() }
        
        cell.field = field
        cell.sex = self.input.profileManager.gender.value ?? .female
        cell.onSelect = { [weak self] (type, index, value) in
            self?.viewModel?.updateField(type, index: index, value: value)
        }
        
        cell.resetInput()
        
        if let profile = self.viewModel?.profileManager.profile.value {
            switch field.fieldType {
            case .height: cell.valueIndex = heightIndex(profile.height.value ?? 0)
            case .hair: cell.valueIndex = Hair(rawValue: profile.hairColor.value ?? 0)?.index() ?? 0
            case .educationLevel: cell.valueIndex = EducationLevel(rawValue: profile.educationLevel.value ?? 0)?.index() ?? 0
            case .children: cell.valueIndex = Children(rawValue: profile.children.value ?? 0)?.index() ?? 0
            case .transport: cell.valueIndex = Transport(rawValue: profile.transport.value ?? 0)?.index() ?? 0
            case .income: cell.valueIndex = Income(rawValue: profile.income.value ?? 0)?.index() ?? 0
            case .property: cell.valueIndex = Property(rawValue: profile.property.value ?? 0)?.index() ?? 0
            case .education: cell.valueText = profile.education
            case .name: cell.valueText = profile.name
            case .status: cell.valueText = profile.statusInfo
            case .tiktok: cell.valueText = profile.tikTok
            case .instagram: cell.valueText = profile.instagram
            case .job: cell.valueText = profile.jobTitle
            case .company: cell.valueText = profile.company
            case .whereLive: cell.valueText = profile.whereLive
            case .bio: cell.valueText = profile.about                
            }
            
            let isNameEmpty: Bool = profile.name == nil || profile.name == "unknown"
            let isCityEmpty: Bool = profile.whereLive == nil || profile.whereLive == "unknown"
            let isStatusEmpty: Bool = profile.statusInfo == nil || profile.statusInfo == "unknown"
            
            if  let defaultField = self.input.defaultField {
                if field.fieldType == defaultField {
                    cell.startEditingWithSelection()
                }
            } else { if field.fieldType == .name, isNameEmpty {
                cell.startEditing()
            } else if field.fieldType == .whereLive, !isNameEmpty, isCityEmpty {
                cell.startEditing()
            } else if field.fieldType == .status, !isNameEmpty, !isCityEmpty, isStatusEmpty {
                cell.startEditing()
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let count = self.viewModel?.configuration.settingsFields.count, indexPath.row == count {
            FeedbackManager.shared.showSuggestion(self, source: .profileFields, feedSource: nil)
            
            return
        }
        
        // Fields
        guard let field = self.viewModel?.configuration.settingsFields[indexPath.row] else { return }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: field.cellIdentifier) as? SettingsProfileFieldCell else { return }
        
        cell.startEditing()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        guard let field = self.viewModel?.configuration.settingsFields[indexPath.row] else { return 0.0 }
        
        if field.fieldType == .bio { return 110.0 }
        if field.fieldType == .status { return 110.0 }
        
        return 72.0
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SettingsProfileViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
    {
        guard let view = touch.view else { return true }
        if view.isDescendant(of: self.tableView) { return false }
        
        return true
    }
}
