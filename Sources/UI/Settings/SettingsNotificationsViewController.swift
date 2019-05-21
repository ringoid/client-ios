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
    let notifications: NotificationService
}

fileprivate struct SettingsNotificationsOption
{
    let cellIdentifier: String
    let height: CGFloat
}

fileprivate enum SettingsNotificationsOptionType: Int
{
    case evening = 0
    case like = 1
    case match = 2
    case message = 3
}

class SettingsNotificationsViewController: BaseViewController
{
    var input: SettingsNotificationsInput!
    
    fileprivate let options = [
        SettingsNotificationsOption(cellIdentifier: "evening_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "like_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "match_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "message_cell", height: 56.0),
    ]
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        assert(self.input != nil)
        
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
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
        let type = SettingsNotificationsOptionType(rawValue: indexPath.row)!
        let cell = tableView.dequeueReusableCell(withIdentifier: option.cellIdentifier) as! SettingsSwitchableCell
        /*
        cell.onValueChanged = { [weak self] valueSwitch in
            switch type {
            case .evening:
                self?.input.notifications.isEveningEnabled.accept(valueSwitch.isOn)
                break
                
            case .like:
                self?.input.notifications.isEveningEnabled.accept(valueSwitch.isOn)
                break
                
            case .evening:
                self?.input.notifications.isEveningEnabled.accept(valueSwitch.isOn)
                break
                
            case .evening:
                self?.input.notifications.isEveningEnabled.accept(valueSwitch.isOn)
                break
            }
        }*/
//        
//        switch type {
//        case .evening: self.input.notifications.isEveningEnabled.bind(to: cell.valueSwitch.rx.isOn).disposed(by: self.disposeBag)
//        case .like: self.input.notifications.isLikeEnabled.bind(to: cell.valueSwitch.rx.isOn).disposed(by: self.disposeBag)
//        case .match: self.input.notifications.isMatchEnabled.bind(to: cell.valueSwitch.rx.isOn).disposed(by: self.disposeBag)
//        case .message: self.input.notifications.isMessageEnabled.bind(to: cell.valueSwitch.rx.isOn).disposed(by: self.disposeBag)
//        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let option = self.options[indexPath.row]
        
        return option.height
    }
}
