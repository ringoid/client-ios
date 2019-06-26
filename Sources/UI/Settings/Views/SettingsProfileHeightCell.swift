//
//  SettingsProfileHeightCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsProfileHeightCell: SettingsProfileFieldCell
{
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.valueField.layer.sublayerTransform = CATransform3DMakeTranslation(0.0, 0.0, 0.0)
    }
}
