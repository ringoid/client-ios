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
    case push = 0
    case theme = 1
    case language = 2
    case legal = 3
    case support = 4
    case delete = 5
}

#else

fileprivate enum SettingsOptionType: Int
{
    case push = 0
    case language = 1
    case legal = 2
    case support = 3
    case delete = 4
}

#endif

class SettingsViewController: BaseViewController
{
    var input: SettingsVMInput!
    
     #if STAGE
    fileprivate let options = [
        SettingsOption(cellIdentifier: "push_cell", height: 56.0),
        SettingsOption(cellIdentifier: "theme_cell", height: 56.0),
        SettingsOption(cellIdentifier: "language_cell", height: 56.0),
        SettingsOption(cellIdentifier: "legal_cell", height: 56.0),
        SettingsOption(cellIdentifier: "support_cell", height: 56.0),
        SettingsOption(cellIdentifier: "delete_cell", height: 96.0)
    ]
    #else
    fileprivate let options = [
        SettingsOption(cellIdentifier: "push_cell", height: 56.0),
        SettingsOption(cellIdentifier: "language_cell", height: 56.0),
        SettingsOption(cellIdentifier: "legal_cell", height: 56.0),
        SettingsOption(cellIdentifier: "support_cell", height: 56.0),
        SettingsOption(cellIdentifier: "delete_cell", height: 96.0)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "legal_vc", let vc = segue.destination as? SettingsLegalViewController {
            vc.input = self.input
        }
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
        self.titleLabel.text = "settings_title".localized()
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
            title: "settings_account_delete_dialog_title".localized(),
            message: "common_uncancellable".localized(),
            preferredStyle: .alert
        )
        alertVC.addAction(UIAlertAction(title: "button_delete".localized(), style: .default, handler: ({ _ in
            self.viewModel?.logout()
        })))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: nil))
        
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
    
    fileprivate func showSettingsAlert()
    {
        let alertVC = UIAlertController(title: nil, message: "settings_push_permission".localized(), preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "button_settings".localized(), style: .default, handler: { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        }))
        alertVC.addAction(UIAlertAction(title: "button_cancel".localized(), style: .cancel, handler: nil))
        
        self.present(alertVC, animated: true, completion: nil)
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
        
        if let option = SettingsOptionType(rawValue: indexPath.row) {
            switch option {
            case .push:
                let notificationsCell = cell as? SettingsNotificationsCell
                notificationsCell?.settingsManager = self.input.settingsManager
                notificationsCell?.onSettingsChangesRequired = { [weak self] in
                    self?.showSettingsAlert()
                }
                notificationsCell?.onHeightUpdate = { [weak self] in
                    self?.tableView.beginUpdates()
                    self?.tableView.endUpdates()
                }
                
                break
                
            default: break
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let option = self.options[indexPath.row]
        
        if option.cellIdentifier == "push_cell" && self.input.settingsManager.isNotificationsAllowed {
            return 88.0
        }
        
        return option.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let option = SettingsOptionType(rawValue: indexPath.row) else { return }
        
        switch option {
        case .push: return            
            #if STAGE
        case .theme: return
            #endif
        case .language:
            self.performSegue(withIdentifier: SegueIds.locale, sender: nil)
            break
            
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
