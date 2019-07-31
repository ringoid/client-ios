//
//  SettingsLocaleViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingsLocaleViewController: BaseViewController
{
    fileprivate var viewModel: SettingsLocaleViewModel?
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: self.tableView.bounds.width, height: 1.0))
        
        self.setupBindings()
    }
        
    override func updateTheme()
    {
        let theme = ThemeManager.shared.theme.value
        let darkThemeSeparatorColor = UIColor(red: 64.0 / 255.0, green: 64.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
        
        self.tableView.separatorColor = (theme == .dark) ? darkThemeSeparatorColor : .lightGray
        self.view.backgroundColor = BackgroundColor().uiColor()        
        self.backBtn.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_language".localized()
    }
    
    // MARK: - Actions
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.viewModel = SettingsLocaleViewModel()
        
        LocaleManager.shared.language.asObservable().subscribe(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)
    }
}

extension SettingsLocaleViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (self.viewModel?.locales.count ?? 0) + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let index = indexPath.row
        if index == self.viewModel?.locales.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "help_cell") as! SettingsLocaleHelpCell
            
            return cell
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "locale_cell") as! SettingsLocaleCell
        
        let locale = self.viewModel?.locales[index]
        let isSelected = LocaleManager.shared.language.value == locale
        
        cell.locale = locale
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let index = indexPath.row
        
        guard let locales = self.viewModel?.locales, index < locales.count else { return }
        
        LocaleManager.shared.language.accept(locales[index])
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        let index = indexPath.row
        if index == self.viewModel?.locales.count {
            return 80.0
        }
        
        return 56.0
    }
}
