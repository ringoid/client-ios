//
//  SettingsProfileStatusCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsProfileStatusCell: SettingsProfileFieldCell
{
    @IBOutlet fileprivate var limitLabel: UILabel!
    
    override var valueText: String?
    {
        didSet {
            guard let text = self.valueText else {
                self.limitLabel.text = "0/30"
                
                return
            }
            
            self.limitLabel.text = "\(text.count)/30"
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        guard let text = textField.text else { return true }
        
        let result = (text as NSString).replacingCharacters(in: range, with: string)
        if result.count > 30 { return false }
        
        self.limitLabel.text = "\(result.count)/30"
        
        return true
    }
}
