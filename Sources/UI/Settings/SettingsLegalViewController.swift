//
//  SettingsLegalViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate struct SettingsLegalOption
{
    let cellIdentifier: String
    let height: CGFloat
}

fileprivate enum SettingsLegalOptionType: Int
{
    case about = 0
    case privacy = 1
}

class SettingsLegalViewController: BaseViewController
{
    fileprivate var viewModel: SettingsLegalViewModel?
    
    fileprivate let options = [
        SettingsLegalOption(cellIdentifier: "about_cell", height: 42.0),
        SettingsLegalOption(cellIdentifier: "policy_cell", height: 42.0),
        ]
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindings()
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
        self.titleLabel.text = "SETTINGS_LEGAL".localized()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: -
    
    func setupBindings()
    {
        self.viewModel = SettingsLegalViewModel()
    }
}

extension SettingsLegalViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let option = self.options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: option.cellIdentifier)!
        
        if let type = SettingsLegalOptionType(rawValue: indexPath.row) {
            switch type {
            case .about:
                (cell as? SettingsLegalAboutCell)?.buildText = self.viewModel?.build.value
            case .privacy: break
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let option = self.options[indexPath.row]
        
        return option.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let option = SettingsLegalOptionType(rawValue: indexPath.row) else { return }
        
        switch option {
        case .about: break
        case .privacy:
            UIApplication.shared.open(AppConfig.policyUrl, options: [:], completionHandler: nil)
            break
        }
    }
}
