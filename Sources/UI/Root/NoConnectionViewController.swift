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
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    
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
        self.noConnectionLabel.textColor = ThirdContentColor().uiColor()
        self.iconImageView.tintColor = ThirdContentColor().uiColor()
    }
    
    override func updateLocale()
    {
        self.noConnectionLabel.text = "error_screen_no_network_connection".localized()
        self.retryBtn.setTitle("error_screen_no_network_connection_button_label".localized(), for: .normal)
    }
    
    // MARK: - Actions
    
    @IBAction fileprivate func onRetry()
    {
        self.dismiss(animated: false, completion: nil)
    }
}
