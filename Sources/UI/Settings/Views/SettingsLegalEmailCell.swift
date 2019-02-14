//
//  SettingsLegalEmailCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalEmailCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var emailLabel: UILabel!
    
    override func updateLocale()
    {
        self.emailLabel.text = "SETTINGS_LEGAL_EMAIL".localized()
    }
    
    override func updateTheme()
    {
        self.emailLabel.textColor = ContentColor().uiColor()
    }
}
