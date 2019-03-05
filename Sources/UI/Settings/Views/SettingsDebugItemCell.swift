//
//  SettingsDebugItemCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 05/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsDebugItemCell: BaseTableViewCell
{
    var item: DebugErrorItem?
    {
        didSet {
            self.titleLabel.text = self.item?.title
        }
    }
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    
    override func updateTheme()
    {
        self.titleLabel.textColor = ContentColor().uiColor()
    }
}
