//
//  SettingsNotificationsMatchCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 20/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsNotificationsMatchCell: SettingsSwitchableCell
{
    @IBOutlet weak var titleLabel: UILabel!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_notifications_match".localized()
    }
}
