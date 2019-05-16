//
//  SettingsSuggestCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsSuggestCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "Suggest improvements"//"settings_support".localized()
    }
}
