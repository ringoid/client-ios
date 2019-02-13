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
    @IBOutlet fileprivate weak var footerView: UIView!
    @IBOutlet fileprivate weak var helpLabel: UILabel!
    @IBOutlet fileprivate weak var backBtn: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = self.footerView
        
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
        self.titleLabel.text = "SETTINGS_LANGUAGE".localized()
        self.helpLabel.attributedText = NSAttributedString(string: "SETTINGS_LOCALE_HELP_LOCALIZE".localized())
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
        return self.viewModel?.locales.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locale_cell") as! SettingsLocaleCell
        
        let locale = self.viewModel?.locales[indexPath.row]
        let isSelected = LocaleManager.shared.language.value == locale
        
        cell.locale = locale
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        guard let language = self.viewModel?.locales[indexPath.row] else { return }
        
        LocaleManager.shared.language.accept(language)
    }
}
