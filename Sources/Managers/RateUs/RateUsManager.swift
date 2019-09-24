//
//  RateUsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class RateUsManager
{
    fileprivate let initialInterval: Double = 24.0 * 3600.0
    fileprivate let maxInterval: Double = 7.0 * 24.0 * 3600.0
    fileprivate let diffVersionsInterval: Double = 24.0 * 3600.0
    
    private init() {}
    
    static let shared = RateUsManager()
    
    func showAlertIfNeeded(_ from: UIViewController)
    {
        guard self.shouldShowAlert() else { return }
        
        let currentVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as?  String) ?? "0"
        
        UserDefaults.standard.set(Date(), forKey: "rate_us_alert_shown_date")
        UserDefaults.standard.set(currentVersion, forKey: "rate_us_alert_shown_version")
        UserDefaults.standard.synchronize()
        
        self.showAlert(from)
    }
    
    func showAlert(_ from: UIViewController)
    {
        let vc = Storyboards.rateUs().instantiateViewController(withIdentifier: "rate_us") as! RateUsViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.view.alpha = 0.0
        vc.onCancel = {
            let currentInterval = (UserDefaults.standard.value(forKey: "rate_us_current_interval") as? Double) ?? self.initialInterval
            let updatedInterval = currentInterval * 2.0
            
            if updatedInterval < self.maxInterval {
                UserDefaults.standard.setValue(updatedInterval, forKey: "rate_us_current_interval")
            }
                        
            UserDefaults.standard.setValue("canceled", forKey: "rate_us_alert_result")
            UserDefaults.standard.synchronize()
        }
        vc.onRate = {
            UserDefaults.standard.setValue(self.initialInterval, forKey: "rate_us_current_interval")
            UserDefaults.standard.setValue("rated", forKey: "rate_us_alert_result")
            UserDefaults.standard.synchronize()
        }
        
        from.present(vc, animated: false, completion: {
            let animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) {
                vc.view.alpha = 1.0
            }
            animator.startAnimation()
        })
    }
    
    // MARK: -
    
    fileprivate func shouldShowAlert() -> Bool
    {
        guard let lastShownDate = UserDefaults.standard.object(forKey: "rate_us_alert_shown_date") as? Date else { return true }
        
        guard let lastShownVersion = UserDefaults.standard.string(forKey: "rate_us_alert_shown_version") else { return true }
        
        guard let lastAlertResult = UserDefaults.standard.string(forKey: "rate_us_alert_result") else { return true }
        
        let currentInterval = (UserDefaults.standard.value(forKey: "rate_us_current_interval") as? Double) ?? self.initialInterval
        let currentVersion = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as?  String) ?? "0"
        
        if lastAlertResult == "canceled" {
            return Date().timeIntervalSince(lastShownDate) > currentInterval
        } else {
            guard let lastVer = Int(lastShownVersion), let currentVer = Int(currentVersion) else { return true }
            guard abs(currentVer - lastVer) > 1 else { return false }
            
            return Date().timeIntervalSince(lastShownDate) > self.diffVersionsInterval
        }
    }
}
