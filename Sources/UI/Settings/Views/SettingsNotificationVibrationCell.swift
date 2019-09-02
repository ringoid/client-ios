//
//  SettingsNotificationVibrationCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsNotificationVibrationCell: SettingsSwitchableCell
{
    @IBOutlet weak var titleLabel: UILabel!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_notifications_vibration".localized()
    }
}

