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
    
    fileprivate var viewModel: SettingsProfileViewModel?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        self.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 260.0, right: 0.0)
        
        self.setupViewModel()
        self.tableView.reloadData()
    }
    
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        let darkThemeSeparatorColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        
        self.tableView.separatorColor = (theme == .dark) ? darkThemeSeparatorColor : .lightGray
        self.view.backgroundColor = BackgroundColor().uiColor()
        self.titleLabel.textColor = ContentColor().uiColor()
        self.backBtn.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_profile".localized()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.input.profileManager.updateProfile()
        self.navigationController?.popViewController(animated: true)
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
            case .height: cell.valueIndex = heightIndex(profile.height.value ?? 175)
            case .hair: cell.valueIndex = Hair(rawValue: profile.hairColor.value ?? 0)?.index() ?? 0
            case .educationLevel: cell.valueIndex = EducationLevel(rawValue: profile.educationLevel.value ?? 0)?.index() ?? 0
            case .children: cell.valueIndex = Children(rawValue: profile.children.value ?? 0)?.index() ?? 0
            case .transport: cell.valueIndex = Transport(rawValue: profile.children.value ?? 0)?.index() ?? 0
            case .income: cell.valueIndex = Income(rawValue: profile.children.value ?? 0)?.index() ?? 0
            case .property: cell.valueIndex = Property(rawValue: profile.children.value ?? 0)?.index() ?? 0
            case .education: cell.valueText = profile.education
            case .name: cell.valueText = profile.name
            case .tiktok: cell.valueText = profile.tikTok
            case .instagram: cell.valueText = profile.instagram
            case .job: cell.valueText = profile.jobTitle
            case .company: cell.valueText = profile.company
            case .whereLive: cell.valueText = profile.whereLive
            case .bio: cell.valueText = profile.about
            }
        }        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let field = self.viewModel?.configuration.settingsFields[indexPath.row] else { return }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: field.cellIdentifier) as? SettingsProfileFieldCell else { return }
        
        cell.startEditing()
    }
}
