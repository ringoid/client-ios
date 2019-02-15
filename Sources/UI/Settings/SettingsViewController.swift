//
//  SettingsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import MessageUI

fileprivate struct SettingsOption
{
    let cellIdentifier: String
    let height: CGFloat
}

#if STAGE

fileprivate enum SettingsOptionType: Int
{
    case theme = 0
    case language = 1
    case legal = 2
    case support = 3
    case delete = 4
}

#else

fileprivate enum SettingsOptionType: Int
{
    case legal = 0
    case support = 1
    case delete = 2
}

#endif

class SettingsViewController: BaseViewController
{
    var input: SettingsVMInput!
    
     #if STAGE
    fileprivate let options = [
        SettingsOption(cellIdentifier: "theme_cell", height: 42.0),
        SettingsOption(cellIdentifier: "language_cell", height: 42.0),
        SettingsOption(cellIdentifier: "legal_cell", height: 42.0),
        SettingsOption(cellIdentifier: "support_cell", height: 42.0),
        SettingsOption(cellIdentifier: "delete_cell", height: 82.0)
    ]
    #else
    fileprivate let options = [
        SettingsOption(cellIdentifier: "legal_cell", height: 42.0),
        SettingsOption(cellIdentifier: "support_cell", height: 42.0),
        SettingsOption(cellIdentifier: "delete_cell", height: 82.0)
    ]
    #endif
    
    fileprivate var viewModel: SettingsViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(input != nil )
        
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.tableView.bounds.width, height: 1.0))
        
        self.setupBindigs()
        self.tableView.reloadData()
    }
    
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        let darkThemeSeparatorColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        
        UIView.animate(withDuration: 0.1) {
            self.tableView.separatorColor = (theme == .dark) ? darkThemeSeparatorColor : .lightGray
            self.view.backgroundColor = BackgroundColor().uiColor()
            self.titleLabel.textColor = ContentColor().uiColor()
            self.backBtn.tintColor = ContentColor().uiColor()
        }
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "SETTINGS_TITLE".localized()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: -
    
    fileprivate func setupBindigs()
    {
        self.viewModel = SettingsViewModel(self.input)
    }
    
    fileprivate func showLogoutAlert()
    {
        let alertVC = UIAlertController(
            title: "SETTINGS_DELETE_ACCOUNT_ALERT_TITLE".localized(),
            message: "SETTINGS_DELETE_ACCOUNT_ALERT_MESSAGE".localized(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "COMMON_DELETE".localized(), style: .default, handler: ({ _ in
            self.viewModel?.logout()
        })))
        alertVC.addAction(UIAlertAction(title: "COMMON_CANCEL".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    fileprivate func showSupportUI()
    {
        guard MFMailComposeViewController.canSendMail() else { return }
        
        let vc = MFMailComposeViewController()
        vc.setToRecipients(["support@ringoid.com"])
        vc.mailComposeDelegate = self
        
        self.present(vc, animated: true, completion: nil)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate
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

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let option = self.options[indexPath.row]
        
        return option.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let option = SettingsOptionType(rawValue: indexPath.row) else { return }
        
        switch option {
            #if STAGE
        case .theme: return
        case .language:
            self.performSegue(withIdentifier: SegueIds.locale, sender: nil)
            break
            #else
            #endif
        case .legal:
            self.performSegue(withIdentifier: SegueIds.legal, sender: nil)
            break
            
        case .support:
            self.showSupportUI()
            break
            
        case .delete:
            self.showLogoutAlert()
            break
        }
    }
}

extension SettingsViewController: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController
{
    fileprivate struct SegueIds
    {
        static let locale = "locale_vc"
        static let legal = "legal_vc"
    }
}
