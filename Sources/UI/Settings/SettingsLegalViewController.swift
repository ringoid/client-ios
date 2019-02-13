//
//  SettingsLegalViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalViewController: BaseViewController
{
    fileprivate var viewModel: SettingsLegalViewModel?
    
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
