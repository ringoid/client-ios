//
//  SettingsLegalPolicyCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalPolicyCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var policyLabel: UILabel!
    
    override func updateLocale()
    {
        self.policyLabel.text = "settings_info_privacy".localized()
    }
    
    override func updateTheme()
    {
        self.policyLabel.textColor = ContentColor().uiColor()
    }
}
