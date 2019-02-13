//
//  SettingsLegalCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 06/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var legalLabel: UILabel!
    
    override func updateLocale()
    {
        self.legalLabel.text = "SETTINGS_LEGAL".localized()
    }
    
    override func updateTheme()
    {
        self.legalLabel.textColor = ContentColor().uiColor()
    }
}
