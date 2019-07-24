//
//  SettingsFilterCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsFilterCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "settings_filter".localized()
    }
}
