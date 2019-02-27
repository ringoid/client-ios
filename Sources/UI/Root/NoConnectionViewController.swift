//
//  NoConnectionViewController.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NoConnectionViewController: BaseViewController
{
    @IBOutlet fileprivate weak var noConnectionLabel: UILabel!
    @IBOutlet fileprivate weak var retryBtn: UIButton!
    
    override var prefersStatusBarHidden: Bool
    {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return ThemeManager.shared.theme.value == .dark ? .lightContent : .default
    }
    
    override func updateTheme()
    {
        self.view.backgroundColor = BackgroundColor().uiColor()
    }
    
    override func updateLocale()
    {
        
    }
    
    // MARK: - Actions
    
    @IBAction fileprivate func onRetry()
    {
        self.dismiss(animated: false, completion: nil)
    }
}
