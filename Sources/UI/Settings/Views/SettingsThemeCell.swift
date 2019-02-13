//
//  SettingsThemeCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingsThemeCell: BaseTableViewCell
{
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var themeSwitch: UISwitch!
    @IBOutlet fileprivate weak var themeLabel: UILabel!
    @IBOutlet fileprivate weak var themeIconView: UIImageView!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.themeSwitch.setOn(ThemeManager.shared.theme.value == .dark, animated: false)
        self.setupBindings()
    }

    override func updateLocale()
    {
        self.themeLabel.text = "THEME_NIGHT_MODE".localized()
    }
    
    override func updateTheme()
    {
        self.themeLabel.textColor = ContentColor().uiColor()
        self.themeIconView.tintColor = ContentColor().uiColor()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.themeSwitch.rx.value.subscribe(onNext: { value in
            ThemeManager.shared.theme.accept(value ? .dark : .light)
        }).disposed(by: self.disposeBag)
    }
}
