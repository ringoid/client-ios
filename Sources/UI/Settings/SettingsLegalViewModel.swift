//
//  SettingsLegalViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 13/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class SettingsLegalViewModel
{
    let build: BehaviorRelay<String> = BehaviorRelay<String>(value: "")
    
    var customerId: BehaviorRelay<String>
    {
        return self.settingsManager.customerId
    }

    fileprivate let settingsManager: SettingsManager
        
    init(_ settingsManager: SettingsManager)
    {
        self.settingsManager = settingsManager
        
        let bundle = Bundle.main
        guard let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return }
        guard let buildVersion = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String else { return }
        
        self.build.accept("\(appVersion).\(buildVersion)")
    }
}
