//
//  SettingsDebugViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsDebugViewController: BaseViewController
{
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    @IBAction func onBack()
    {
        self.navigationController?.popViewController(animated: true)
    }
}
