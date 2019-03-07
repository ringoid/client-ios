//
//  SettingsLegalTermsCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalTermsCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var termsLabel: UILabel!
    
    override func updateLocale()
    {
        self.termsLabel.text = "settings_info_terms".localized()
    }
    
    override func updateTheme()
    {
        self.termsLabel.textColor = ContentColor().uiColor()
    }
}
