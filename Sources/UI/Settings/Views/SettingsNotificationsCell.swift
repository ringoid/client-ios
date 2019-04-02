//
//  SettingsNotificationsCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 01/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class SettingsNotificationsCell: BaseTableViewCell
{
    @IBOutlet fileprivate weak var pushSwitch: UISwitch!
    @IBOutlet fileprivate weak var pushLabel: UILabel!
    @IBOutlet fileprivate weak var detailsLabel: UILabel!
    
    var settingsManager: SettingsManager? {
        didSet {
            self.updateUI()
        }
    }
    
    var onSettingsChangesRequired: (()->())?
    var onHeightUpdate: (()->())?
    
    override func updateLocale()
    {
        self.pushLabel.text = "settings_push".localized()
        self.detailsLabel.text = "settings_push_details".localized()
    }
    
    override func updateTheme()
    {
        self.pushLabel.textColor = ContentColor().uiColor()
    }
    
    // MARK: - Actions
    
    @IBAction func onValueChanged()
    {
        guard let isGranted = self.settingsManager?.notifications.isGranted.value, isGranted else {
            self.pushSwitch.setOn(false, animated: true)
            self.onSettingsChangesRequired?()
            
            return
        }
        
        self.settingsManager?.isNotificationsAllowed = self.pushSwitch.isOn
        self.settingsManager?.updateRemoteSettings()
        self.onHeightUpdate?()
        self.updateDetails()
    }
    
    // MARK: -
    
    fileprivate func updateUI()
    {
        let isEnabled = self.settingsManager?.isNotificationsAllowed ?? false
        self.pushSwitch.setOn(isEnabled, animated: isEnabled)
        self.detailsLabel.alpha = self.settingsManager?.isNotificationsAllowed == true ? 1.0 : 0.0
    }
    
    fileprivate func updateDetails()
    {
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.detailsLabel.alpha = self.settingsManager?.isNotificationsAllowed == true ? 1.0 : 0.0
        }

        animator.startAnimation()
    }
}
