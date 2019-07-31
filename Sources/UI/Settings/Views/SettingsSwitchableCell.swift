//
//  SettingsSwitchableCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 20/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsSwitchableCell: BaseTableViewCell
{
    var onValueChanged: ((UISwitch) -> ())?
    
    @IBOutlet weak var valueSwitch: UISwitch!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        
        self.valueSwitch.addTarget(self, action: #selector(valueChangedAction), for: .valueChanged)
    }
    
    @objc func valueChangedAction()
    {
        self.onValueChanged?(self.valueSwitch)
    }
    
    func changeValue()
    {
        self.valueSwitch.setOn(!self.valueSwitch.isOn, animated: true)
        self.onValueChanged?(self.valueSwitch)
    }
}
