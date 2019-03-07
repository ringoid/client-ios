//
//  SettingsDeleteCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 06/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsDeleteCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var deleteLabel: UILabel!
    
    override func updateLocale()
    {
        self.deleteLabel.text = "settings_account_delete".localized()
    }
}
