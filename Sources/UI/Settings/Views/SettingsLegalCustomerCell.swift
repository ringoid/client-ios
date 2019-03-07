//
//  SettingsLegalCustomerCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 18/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsLegalCustomerCell: BaseTableViewCell
{
    var customerId: String = ""
    {
        didSet {
            self.idLabel.text = self.customerId
        }
    }
    
    @IBOutlet fileprivate weak var customerLabel: UILabel!
    @IBOutlet fileprivate weak var idLabel: UILabel!
    
    override func updateLocale()
    {
        self.customerLabel.text = "settings_info_customer_info".localized()
    }
    
    override func updateTheme()
    {
        self.customerLabel.textColor = ContentColor().uiColor()
        self.idLabel.textColor = ThirdContentColor().uiColor()
    }
}
