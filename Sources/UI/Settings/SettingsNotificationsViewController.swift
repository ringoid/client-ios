//
//  SettingsNotificationsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 20/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

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
    fileprivate let options = [
        SettingsNotificationsOption(cellIdentifier: "evening_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "like_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "match_cell", height: 56.0),
        SettingsNotificationsOption(cellIdentifier: "message_cell", height: 56.0),
    ]
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: option.cellIdentifier)!
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let option = self.options[indexPath.row]
        
        return option.height
    }
}
