//
//  SettingsViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct SettingsVMInput
{
    let settingsManager: SettingsManager
    let actionsManager: ActionsManager
    let errorsManager: ErrorsManager
    let profileManager: UserProfileManager
    let device: DeviceService
    let db: DBService
}

class SettingsViewModel
{
    fileprivate let settingsManger: SettingsManager
    
    init(_ input: SettingsVMInput)
    {
        self.settingsManger = input.settingsManager
    }
    
    func logout(onError: (()->())?)
    {
        self.settingsManger.logout(onError: onError)
    }
}
