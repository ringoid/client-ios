//
//  ThemeViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class ThemeViewController: UIViewController
{
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return ThemeManager.shared.theme == .dark ? .lightContent : .default
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
}
