//
//  SettingsNotificationsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 20/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct SettingsNotificationsInput
{
    let settingsManager: SettingsManager
}

fileprivate struct SettingsNotificationsOption
{
    let cellIdentifier: String
    let height: CGFloat
}

fileprivate enum SettingsNotificationsOptionType: Int
{
    case vibration = 0
    case message = 1
    case match = 2
    case like = 3
    case evening = 4
    case suggest = 5
}

class SettingsNotificationsViewController: BaseViewController
{
    var input: SettingsNotificationsInput!
    
    fileprivate var options = [
        SettingsNotificationsOption(cellIdentifier: "vibration_cell", height: 96.0),
        SettingsNotificationsOption(cellIdentifier: "message_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "match_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "like_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "evening_cell", height: 96.0),
        SettingsNotificationsOption(cellIdentifier: "profile_suggest_cell", height: 124.0),
    ]
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
        
        if !self.input.settingsManager.impact.isAvailable {
            self.options = [                
                SettingsNotificationsOption(cellIdentifier: "message_cell", height: 56.0),
                SettingsNotificationsOption(cellIdentifier: "match_cell", height: 56.0),
                SettingsNotificationsOption(cellIdentifier: "like_cell", height: 56.0),
                SettingsNotificationsOption(cellIdentifier: "evening_cell", height: 96.0),
                SettingsNotificationsOption(cellIdentifier: "profile_suggest_cell", height: 124.0),
            ]
        }
        
        self.setupBindings()
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
        self.titleLabel.text = "settings_push".localized()        
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.settingsManager.notifications.isGranted.asObservable().subscribe(onNext: { [weak self] _ in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }).disposed(by: self.disposeBag)
    }
}

extension SettingsNotificationsViewController: UITableViewDataSource, UITableViewDelegate
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
        let isAvailable = self.input.settingsManager.impact.isAvailable
        let type = SettingsNotificationsOptionType(rawValue: isAvailable ? indexPath.row : (indexPath.row + 1))!
        
        guard type != .suggest else { return tableView.dequeueReusableCell(withIdentifier: option.cellIdentifier)! }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: option.cellIdentifier) as! SettingsSwitchableCell
        
        let notifications = self.input.settingsManager.notifications
        let impact = self.input.settingsManager.impact
        let isEnabledBySystem = notifications.isGranted.value
        
        switch type {
        case .vibration: cell.valueSwitch.isOn = impact.isEnabled.value
        case .evening: cell.valueSwitch.isOn = notifications.isEveningEnabled.value && isEnabledBySystem
        case .like: cell.valueSwitch.isOn = notifications.isLikeEnabled.value && isEnabledBySystem
        case .match: cell.valueSwitch.isOn = notifications.isMatchEnabled.value && isEnabledBySystem
        case .message: cell.valueSwitch.isOn = notifications.isMessageEnabled.value && isEnabledBySystem
            
        default: break
        }
        
        cell.onValueChanged = { [weak self] valueSwitch in
            guard let `self` = self else { return }
            
            if type == .vibration {
                impact.isEnabled.accept(valueSwitch.isOn)
                
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                
                return
            }
            
            if !notifications.isGranted.value {
                valueSwitch.setOn(false, animated: true)
                
                if !notifications.isRegistered  {
                    notifications.register()
                } else {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } else {
                switch type {
                case .evening: notifications.isEveningEnabled.accept(valueSwitch.isOn)
                case .like: notifications.isLikeEnabled.accept(valueSwitch.isOn)
                case .match: notifications.isMatchEnabled.accept(valueSwitch.isOn)
                case .message: notifications.isMessageEnabled.accept(valueSwitch.isOn)
                    
                default: break
                }
                
                self.input.settingsManager.updateRemoteSettings()
                
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
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
        let isAvailable = self.input.settingsManager.impact.isAvailable
        let type = SettingsNotificationsOptionType(rawValue: isAvailable ? indexPath.row : (indexPath.row + 1))!
        guard type != .suggest else {
            FeedbackManager.shared.showSuggestion(self, source: .notificationsSettings, feedSource: nil)
            
            return
        }
                
        let cell = tableView.cellForRow(at: indexPath) as! SettingsSwitchableCell
        cell.changeValue()
    }
}
