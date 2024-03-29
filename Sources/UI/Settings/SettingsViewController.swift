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
import DeviceKit

fileprivate struct SettingsOption
{
    let cellIdentifier: String
    let height: CGFloat
}

#if STAGE

fileprivate enum SettingsOptionType: Int
{
    case filter = 0
    case profile = 1
    case push = 2
    case theme = 3
    case language = 4
    case legal = 5
    case support = 6
    case suggest = 7
    case delete = 8
}

#else

fileprivate enum SettingsOptionType: Int
{
    case filter = 0
    case profile = 1
    case push = 2
    case language = 3
    case legal = 4
    case support = 5
    case suggest = 6
    case delete = 7
}

#endif

class SettingsViewController: BaseViewController
{
    var input: SettingsVMInput!
    
     #if STAGE
    fileprivate let options = [
        SettingsOption(cellIdentifier: "filter_cell", height: 56.0),
        SettingsOption(cellIdentifier: "profile_cell", height: 56.0),
        SettingsOption(cellIdentifier: "push_cell", height: 56.0),
        SettingsOption(cellIdentifier: "theme_cell", height: 56.0),
        SettingsOption(cellIdentifier: "language_cell", height: 56.0),
        SettingsOption(cellIdentifier: "legal_cell", height: 56.0),
        SettingsOption(cellIdentifier: "support_cell", height: 56.0),
        SettingsOption(cellIdentifier: "suggest_cell", height: 56.0),
        SettingsOption(cellIdentifier: "delete_cell", height: 96.0)
    ]
    #else
    fileprivate let options = [
        SettingsOption(cellIdentifier: "filter_cell", height: 56.0),
        SettingsOption(cellIdentifier: "profile_cell", height: 56.0),
        SettingsOption(cellIdentifier: "push_cell", height: 56.0),
        SettingsOption(cellIdentifier: "language_cell", height: 56.0),
        SettingsOption(cellIdentifier: "legal_cell", height: 56.0),
        SettingsOption(cellIdentifier: "support_cell", height: 56.0),
        SettingsOption(cellIdentifier: "suggest_cell", height: 56.0),
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
        if segue.identifier == SegueIds.legal, let vc = segue.destination as? SettingsLegalViewController {
            vc.input = self.input
        }
        
        if segue.identifier == SegueIds.pushes, let vc = segue.destination as? SettingsNotificationsViewController {
            vc.input = SettingsNotificationsInput(settingsManager: self.input.settingsManager)
        }
        
        if segue.identifier == SegueIds.profile, let vc = segue.destination as? SettingsProfileViewController {
            vc.input = SettingsProfileVMInput(
                profileManager: self.input.profileManager,
                db: self.input.db,
                navigationManager: self.input.navigationManager,
                defaultField: nil
            )
        }
        
        if segue.identifier == SegueIds.filter, let vc = segue.destination as? SettingsFilterViewController {
            vc.input = SettingsFilterVMInput(
                filter: self.input.filter,
                lmm: self.input.lmm,
                newFaces: self.input.newFaces
            )
        }
    }
    
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        let darkThemeSeparatorColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        
        UIView.animate(withDuration: 0.1) {
            self.tableView.separatorColor = (theme == .dark) ? darkThemeSeparatorColor : .lightGray
            self.view.backgroundColor = BackgroundColor().uiColor()            
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
        self.input.settingsManager.updateRemoteSettings()
        
        ModalUIManager.shared.hide(animated: true)
    }
    
    // MARK: -
    
    fileprivate func setupBindigs()
    {
        self.viewModel = SettingsViewModel(self.input)
    }

    fileprivate func showSupportUI()
    {
        guard MFMailComposeViewController.canSendMail() else { return }
        
        let device = Device.current
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
        
        let vc = MFMailComposeViewController()
        vc.setSubject("Ringoid iOS  App \(appVersion), [\(device.description)], [\(device.systemVersion)]")
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
        
        let isConnectionAvailable = self.input.actionsManager.checkConnectionState()
        
        switch option {
        case .filter:
            self.performSegue(withIdentifier: SegueIds.filter, sender: nil)
            break
            
        case .profile:
            self.performSegue(withIdentifier: SegueIds.profile, sender: nil)
            break
            
        case .push:
            self.performSegue(withIdentifier: SegueIds.pushes, sender: nil)
            break
            
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
            
        case .suggest:
            if isConnectionAvailable {
                FeedbackManager.shared.showSuggestion(self, source: .settings, feedSource: nil)
            }
            break
            
        case .delete:
            if isConnectionAvailable {
                let settingsManager = self.input.settingsManager
                FeedbackManager.shared.showDeletion({ [weak self] in
                    self?.block()
                    settingsManager.logout(onError: { [weak self] in
                        self?.unblock()
                    })
                    
                    }, from: self)
            }
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
        static let filter = "filter_vc"
        static let locale = "locale_vc"
        static let legal = "legal_vc"
        static let pushes = "pushes_vc"
        static let profile = "profile_vc"
    }
}
