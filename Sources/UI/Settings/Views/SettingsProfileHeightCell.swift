//
//  SettingsProfileHeightCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsProfileHeightCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var iconView: UIImageView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var valueField: UITextField!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
        self.tintColor = ContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.titleLabel.text = "profile_field_height".localized()
    }
}
