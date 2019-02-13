//
//  SettingsLocaleCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLocaleCell: BaseTableViewCell
{
    var locale: Language?
    {
        didSet {
            self.titleLabel.text = locale?.title()
        }
    }
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
    }
    
}
