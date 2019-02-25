//
//  SettingsLanguageCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 06/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLanguageCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "SETTINGS_LANGUAGE".localized()
    }
}
