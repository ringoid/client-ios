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

fileprivate struct SettingsOption
{
    let cellIdentifier: String
    let height: CGFloat
}

fileprivate enum SettinsOptionType: Int
{
    case theme = 0
    case language = 1
    case legal = 2
    case support = 3
    case delete = 4
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
    
    fileprivate var viewModel: SettingsViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    // Options controls
    fileprivate weak var themeSwitch: UISwitch?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setupBindigs()
        self.tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: -
    
    fileprivate func setupBindigs()
    {
        self.viewModel = SettingsViewModel()
    }
    
    fileprivate func setupThemeBindings()
    {
        self.themeSwitch?.setOn(self.viewModel?.theme.value == .dark, animated: false)
        self.themeSwitch?.rx.value.subscribe(onNext: { [weak self] value in
            self?.viewModel?.theme.accept(value ? .dark : .light)
        }).disposed(by: self.disposeBag)
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
        
        switch SettinsOptionType(rawValue: indexPath.row)! {
        case .theme:
            self.themeSwitch = (cell as? SettingsThemeCell)?.themeSwitch
            self.setupThemeBindings()
            break
            
        case .language: break
        case .legal: break
        case .support: break
        case .delete: break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let option = self.options[indexPath.row]
        
        return option.height
    }
}
