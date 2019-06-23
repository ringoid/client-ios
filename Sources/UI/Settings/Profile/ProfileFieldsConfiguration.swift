//
//  ProfileFieldsConfiguration.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ProfileField {
    let title: String
    let icon: String
    let placeholder: String
    let cellIdentifier: String
    let fieldType: ProfileFieldType
}

class ProfileFieldsConfiguration
{
    fileprivate var profileManager: UserProfileManager
    
    let settingsFields: [ProfileField] = [
        ProfileField(
            title: "profile_field_height",
            icon: "profile_fields_ruler",
            placeholder: "175",
            cellIdentifier: "profile_height_cell",
            fieldType: .height
        ),
        ProfileField(
            title: "profile_field_hair",
            icon: "profile_fields_hair",
            placeholder: "profile_field_not_selected",
            cellIdentifier: "profile_field_cell",
            fieldType: .hair 
        ),
        ProfileField(
            title: "profile_field_education",
            icon: "profile_fields_education",
            placeholder: "profile_field_not_selected",
            cellIdentifier: "profile_field_cell",
            fieldType: .education
        )
    ]
    
    init(_ profileManager: UserProfileManager)
    {
        self.profileManager = profileManager
    }
}
