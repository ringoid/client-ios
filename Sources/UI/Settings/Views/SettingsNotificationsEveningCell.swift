//
//  SettingsNotificationsEveningCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 20/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingsNotificationsEveningCell: SettingsSwitchableCell
{

    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.valueSwitch.rx.isOn.asObservable().subscribe(onNext: { [weak self] value in
            self?.detailsLabel.isHidden = !value
        }).disposed(by: self.disposeBag)
    }
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_notifications_evening".localized()
        self.detailsLabel.text = "settings_push_details".localized()
    }
}
