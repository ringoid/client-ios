//
//  SettingsLocaleHelpCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLocaleHelpCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    
    override func updateTheme()
    {
        self.descriptionLabel.textColor = ThirdContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.descriptionLabel.attributedText = NSAttributedString(string: "settings_language_help".localized())
    }
}
