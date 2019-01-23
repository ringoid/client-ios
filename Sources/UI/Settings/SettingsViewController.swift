//
//  SettingsViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

fileprivate struct SettingsOption
{
    let cellIdentifier: String
    let height: CGFloat
}

class SettingsViewController: ThemeViewController
{
    fileprivate let options = [
        SettingsOption(cellIdentifier: "theme_cell", height: 42.0),
        SettingsOption(cellIdentifier: "language_cell", height: 42.0),
        SettingsOption(cellIdentifier: "legal_cell", height: 42.0),
        SettingsOption(cellIdentifier: "support_cell", height: 42.0),
        SettingsOption(cellIdentifier: "delete_cell", height: 82.0)
    ]
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.dismiss(animated: true, completion: nil)
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
}
