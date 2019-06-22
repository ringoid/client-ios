//
//  SettingsProfileViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct SettingsProfileVMInput
{
    let profileManager: UserProfileManager
}

class SettingsProfileViewModel
{
    let configuration: ProfileFieldsConfiguration
    
    init(_ input: SettingsProfileVMInput)
    {
        self.configuration = ProfileFieldsConfiguration(input.profileManager)
    }
}
