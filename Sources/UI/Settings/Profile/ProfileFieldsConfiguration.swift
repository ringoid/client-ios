//
//  ProfileFieldsConfiguration.swift
//  ringoid
//
//  Created by Victor Sukochev on 22/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ProfileField
{
    let title: String
    let icon: String
    let placeholder: String
    let cellIdentifier: String
    let fieldType: ProfileFieldType
}

struct ProfileFileRow
{
    let title: String
    let icon: String?
}

class ProfileFieldsConfiguration
{
    fileprivate var profileManager: UserProfileManager
    
    let settingsFields: [ProfileField] = [
        ProfileField(
            title: "profile_field_name",
            icon: "profile_fields_education",
            placeholder: "",
            cellIdentifier: "profile_field_cell",
            fieldType: .name
        ),
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
            title: "profile_field_education_level",
            icon: "profile_fields_education",
            placeholder: "profile_field_not_selected",
            cellIdentifier: "profile_field_cell",
            fieldType: .educationLevel
        ),
        ProfileField(
            title: "profile_field_education",
            icon: "profile_fields_education",
            placeholder: "",
            cellIdentifier: "profile_field_cell",
            fieldType: .education
        )
    ]
    
    init(_ profileManager: UserProfileManager)
    {
        self.profileManager = profileManager
    }
    
    func colums(_ profile: Profile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let rawValue = profile.children.value, let children = Children(rawValue: rawValue), children != .unknown {
            rows.append(ProfileFileRow(
                title: children.title(),
                icon: "profile_fields_children"
            ))
        }
        
        if let title = profile.education, title != "unknown" {
            rows.append(ProfileFileRow(
                title: title,
                icon: nil
            ))
        }
        
        if let rawValue = profile.educationLevel.value, let level = EducationLevel(rawValue: rawValue), level != .unknown {
            rows.append(ProfileFileRow(
                title: level.title(),
                icon: "profile_fields_education"
            ))
        }
        
        if let rawValue = profile.income.value, let income = Income(rawValue: rawValue), income != .unknown {
            rows.append(ProfileFileRow(
                title: income.title(),
                icon: "profile_fields_income"
            ))
        }
        
        if let rawValue = profile.property.value, let property = Property(rawValue: rawValue), property != .unknown {
            rows.append(ProfileFileRow(
                title: property.title(),
                icon: "profile_fields_house"
            ))
        }
        
        if let title = profile.jobTitle, title != "unknown" {
            rows.append(ProfileFileRow(
                title: title,
                icon: nil
            ))
        }
        
        if let rawValue = profile.transport.value, let transport = Transport(rawValue: rawValue), transport != .unknown {
            rows.append(ProfileFileRow(
                title: transport.title(),
                icon: "profile_fields_transport"
            ))
        }
        
        if let title = profile.tikTok, title != "unknown" {
            rows.append(ProfileFileRow(
                title: title,
                icon: nil
            ))
        }
        
        if let title = profile.instagram, title != "unknown" {
            rows.append(ProfileFileRow(
                title: title,
                icon: nil
            ))
        }
        
        return rows
    }
}
