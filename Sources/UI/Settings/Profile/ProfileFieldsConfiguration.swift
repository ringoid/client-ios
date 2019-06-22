//
//  ProfileFieldsConfiguration.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ProfileFieldsConfiguration
{
    fileprivate var profileManager: UserProfileManager
    
    init(_ profileManager: UserProfileManager)
    {
        self.profileManager = profileManager
    }
}
