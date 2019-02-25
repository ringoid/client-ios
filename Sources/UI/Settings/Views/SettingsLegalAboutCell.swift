//
//  SettingsLegalAboutCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalAboutCell: BaseTableViewCell
{
    
    var buildText: String?
    {
        didSet {
            self.buildLabel.text = buildText
        }
    }
    
    @IBOutlet fileprivate weak var aboutLabel: UILabel!
    @IBOutlet fileprivate weak var buildLabel: UILabel!
    
    override func updateLocale()
    {
        self.aboutLabel.text = "COMMON_ABOUT".localized()
    }
    
    override func updateTheme()
    {
        self.aboutLabel.textColor = ContentColor().uiColor()        
    }
}