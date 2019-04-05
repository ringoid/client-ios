//
//  SettingsNotificationsCell.swift
//  ringoid
//
//  Created by Victor Sukochev on 01/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SettingsNotificationsCell: BaseTableViewCell
{
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    @IBOutlet fileprivate weak var pushSwitch: UISwitch!
    @IBOutlet fileprivate weak var pushLabel: UILabel!
    @IBOutlet fileprivate weak var detailsLabel: UILabel!
    
    var settingsManager: SettingsManager? {
        didSet {
            self.setupBindings()
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
            self.settingsManager?.isNotificationsAllowed = true
            self.pushSwitch.setOn(false, animated: true)
            
            if let isRegistered = self.settingsManager?.notifications.isRegistered, !isRegistered {
                self.settingsManager?.notifications.register()
            } else {
                self.onSettingsChangesRequired?()
            }
            
            return
        }
        
        self.settingsManager?.isNotificationsAllowed = self.pushSwitch.isOn
        self.settingsManager?.updateRemoteSettings()
        self.onHeightUpdate?()
        self.updateDetails()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.disposeBag = DisposeBag()
        self.settingsManager?.notifications.isGranted.asObservable().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
            self?.updateUI()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateUI()
    {
        let isEnabled = self.settingsManager?.isNotificationsAllowed ?? false
        self.pushSwitch.setOn(isEnabled, animated: isEnabled)
        self.detailsLabel.alpha = self.settingsManager?.isNotificationsAllowed == true ? 1.0 : 0.0
        self.onHeightUpdate?()
    }
    
    fileprivate func updateDetails()
    {
        let animator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) {
            self.detailsLabel.alpha = self.settingsManager?.isNotificationsAllowed == true ? 1.0 : 0.0
        }

        animator.startAnimation()
    }
}
