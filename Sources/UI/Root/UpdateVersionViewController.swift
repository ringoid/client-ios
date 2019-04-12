//
//  UpdateVersionViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class UpdateVersionViewController: BaseViewController
{
    @IBOutlet weak var storeBtn: UIButton!
    
    static func create() -> UpdateVersionViewController
    {
        let storyboard = Storyboards.root()
        let vc = storyboard.instantiateViewController(withIdentifier: "update_version_vc") as! UpdateVersionViewController
        
        return vc
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {        
        self.storeBtn.setTitle("error_screen_old_app_version_button_label".localized(), for: .normal)
    }
    
    // MARK: - Actions
    
    @IBAction fileprivate func onLink()
    {
        UIApplication.shared.open(AppConfig.appstoreUrl, options: [:], completionHandler: nil)
    }
}
