//
//  SettingsLegalLicensesCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalLicensesCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var licensesLabel: UILabel!
    
    override func updateLocale()
    {
        self.licensesLabel.text = "settings_info_licenses".localized()
    }
    
    override func updateTheme()
    {
        self.licensesLabel.textColor = ContentColor().uiColor()
    }
}
