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
    let icon: String?
    let placeholder: String?
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
            icon: "settings_profile",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .name
        ),
        ProfileField(
            title: "profile_field_where_live",
            icon: "profile_fields_marker",
            placeholder: "profile_field_where_live_placeholder".localized(),
            cellIdentifier: "profile_field_cell",
            fieldType: .whereLive
        ),
        ProfileField(
            title: "profile_field_bio",
            icon: "profile_fields_bio",
            placeholder: nil,
            cellIdentifier: "profile_field_text_cell",
            fieldType: .bio
        ),
        ProfileField(
            title: "profile_field_instagram",
            icon: "profile_fields_instagram",
            placeholder: "@username",
            cellIdentifier: "profile_field_cell",
            fieldType: .instagram
        ),
        ProfileField(
            title: "profile_field_tiktok",
            icon: "profile_fields_tiktok",
            placeholder: "@username",
            cellIdentifier: "profile_field_cell",
            fieldType: .tiktok
        ),
        ProfileField(
            title: "profile_field_job",
            icon: "profile_fields_job",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .job
        ),
        ProfileField(
            title: "profile_field_company",
            icon: "profile_fields_job",
            placeholder: "profile_field_company_placeholder".localized(),
            cellIdentifier: "profile_field_cell",
            fieldType: .company
        ),
        ProfileField(
            title: "profile_field_education",
            icon: "profile_fields_education",
            placeholder: "profile_field_education_placeholder".localized(),
            cellIdentifier: "profile_field_cell",
            fieldType: .education
        ),
        ProfileField(
            title: "profile_field_height",
            icon: "profile_fields_ruler",
            placeholder: nil,
            cellIdentifier: "profile_height_cell",
            fieldType: .height
        ),
        ProfileField(
            title: "profile_field_hair",
            icon: "profile_fields_hair",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .hair
        ),
        ProfileField(
            title: "profile_field_education_level",
            icon: "profile_fields_education",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .educationLevel
        ),
        ProfileField(
            title: "profile_field_children",
            icon: "profile_fields_children",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .children
        ),
        ProfileField(
            title: "profile_field_income",
            icon: "profile_fields_income",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .income
        ),
        ProfileField(
            title: "profile_field_property",
            icon: "profile_fields_house",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .property
        ),
        ProfileField(
            title: "profile_field_transport",
            icon: "profile_fields_transport",
            placeholder: nil,
            cellIdentifier: "profile_field_cell",
            fieldType: .transport
        ),
    ]
    
    init(_ profileManager: UserProfileManager)
    {
        self.profileManager = profileManager
    }
    
    func leftColums(_ profile: Profile) -> [ProfileFileRow]
    {
        if let genderStr = profile.gender, let gender = Sex(rawValue: genderStr) {
            switch gender {
            case .male: return self.leftColumsMale(profile)
            case .female: return self.leftColumsFemale(profile)
            }
        } else if let oldGender = self.profileManager.gender.value?.opposite() {
            switch oldGender {
            case .male: return self.leftColumsMale(profile)
            case .female: return self.leftColumsFemale(profile)
            }
        }
        
        return []
    }
    
    func leftColumsMale(_ profile: Profile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let rawValue = profile.children.value, let children = Children(rawValue: rawValue), children != .unknown {
            rows.append(ProfileFileRow(
                title: children.title(),
                icon: "profile_fields_children"
            ))
        }
        
        if let rawValue = profile.income.value, let income = Income(rawValue: rawValue), income != .unknown {
            rows.append(ProfileFileRow(
                title: income.title(),
                icon: "profile_fields_income"
            ))
        }
        
        if let jobTitle = profile.jobTitle, jobTitle != "unknown", !jobTitle.isEmpty {
            var title = jobTitle
            
            if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty {
                title += ", \(companyTitle)"
            }
            
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_job"
            ))
        } else if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty  {
            rows.append(ProfileFileRow(
                title: companyTitle,
                icon: "profile_fields_job"
            ))
        }
        
        if let title = profile.education, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_education"
            ))
        }
        
        if let rawValue = profile.educationLevel.value, let level = EducationLevel(rawValue: rawValue), level != .unknown {
            rows.append(ProfileFileRow(
                title: level.title(),
                icon: "profile_fields_education"
            ))
        }
        
        if let rawValue = profile.property.value, let property = Property(rawValue: rawValue), property != .unknown {
            rows.append(ProfileFileRow(
                title: property.title(),
                icon: "profile_fields_house"
            ))
        }
        
        if let rawValue = profile.transport.value, let transport = Transport(rawValue: rawValue), transport != .unknown {
            rows.append(ProfileFileRow(
                title: transport.title(),
                icon: "profile_fields_transport"
            ))
        }
        
        if let title = profile.tikTok, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "TikTok: " +  title,
                icon: "profile_fields_tiktok"
            ))
        }
        
        if let title = profile.instagram, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "Instagram: " +  title,
                icon: "profile_fields_instagram"
            ))
        }
        
        return rows
    }
    
    func leftColumsFemale(_ profile: Profile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let rawValue = profile.children.value, let children = Children(rawValue: rawValue), children != .unknown {
            rows.append(ProfileFileRow(
                title: children.title(),
                icon: "profile_fields_children"
            ))
        }
        
        if let title = profile.education, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_education"
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
        
        if let jobTitle = profile.jobTitle, jobTitle != "unknown", !jobTitle.isEmpty {
            var title = jobTitle
            
            if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty {
                title += ", \(companyTitle)"
            }
            
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_job"
            ))
        } else if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty  {
            rows.append(ProfileFileRow(
                title: companyTitle,
                icon: "profile_fields_job"
            ))
        }
        
        if let rawValue = profile.transport.value, let transport = Transport(rawValue: rawValue), transport != .unknown {
            rows.append(ProfileFileRow(
                title: transport.title(),
                icon: "profile_fields_transport"
            ))
        }
        
        if let title = profile.tikTok, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "TikTok: " + title,
                icon: "profile_fields_tiktok"
            ))
        }
        
        if let title = profile.instagram, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "Instagram: " + title,
                icon: "profile_fields_instagram"
            ))
        }
        
        return rows
    }
    
    func rightColums(_ profile: Profile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let title = profile.whereLive, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_marker"
            ))
        }
        
        if let title = profile.distanceText, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "common_location"
            ))
        }
        
        if let value = profile.height.value, value != 0 {
            let index = heightIndex(value)
            rows.append(ProfileFileRow(
                title: Height.title(index),
                icon: "profile_fields_ruler"
            ))
        }
        
        if let value = profile.hairColor.value, let hairColor = Hair(rawValue: value), hairColor != .unknown {
            if let genderStr = profile.gender, let gender = Sex(rawValue: genderStr) {
                rows.append(ProfileFileRow(
                    title: hairColor.title(gender),
                    icon: "profile_fields_hair"
                ))
            } else if let oldGender = self.profileManager.gender.value?.opposite() {
                rows.append(ProfileFileRow(
                    title: hairColor.title(oldGender),
                    icon: "profile_fields_hair"
                ))
            }
        }
        
        return rows
    }
    
    // MARK: - User
    
    func rightUserColumns(_ profile: UserProfile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let title = profile.whereLive, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_marker"
            ))
        }
        
        if let value = profile.height.value, value != 0 {
            let index = heightIndex(value)
            rows.append(ProfileFileRow(
                title: Height.title(index),
                icon: "profile_fields_ruler"
            ))
        }
        
        if let value = profile.hairColor.value, let hairColor = Hair(rawValue: value), hairColor != .unknown {
            let gender: Sex = self.profileManager.gender.value == .male ? .male : .female
            rows.append(ProfileFileRow(
                title: hairColor.title(gender),
                icon: "profile_fields_hair"
            ))
        }
        
        return rows
    }
    
    func leftUserColumns(_ profile: UserProfile) -> [ProfileFileRow]
    {
        guard let gender = self.profileManager.gender.value else { return [] }
        
        switch gender {
        case .male: return self.leftUserColumnsMale(profile)
        case .female: return self.leftUserColumnsFemale(profile)
        }
    }
    
    func leftUserColumnsMale(_ profile: UserProfile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let rawValue = profile.income.value, let income = Income(rawValue: rawValue), income != .unknown {
            rows.append(ProfileFileRow(
                title: income.title(),
                icon: "profile_fields_income"
            ))
        }
        
        if let jobTitle = profile.jobTitle, jobTitle != "unknown", !jobTitle.isEmpty {
            var title = jobTitle
            
            if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty {
                title += ", \(companyTitle)"
            }
            
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_job"
            ))
        } else if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty  {
            rows.append(ProfileFileRow(
                title: companyTitle,
                icon: "profile_fields_job"
            ))
        }
        
        if let rawValue = profile.children.value, let children = Children(rawValue: rawValue), children != .unknown {
            rows.append(ProfileFileRow(
                title: children.title(),
                icon: "profile_fields_children"
            ))
        }
        
        if let rawValue = profile.property.value, let property = Property(rawValue: rawValue), property != .unknown {
            rows.append(ProfileFileRow(
                title: property.title(),
                icon: "profile_fields_house"
            ))
        }
        
        if let rawValue = profile.transport.value, let transport = Transport(rawValue: rawValue), transport != .unknown {
            rows.append(ProfileFileRow(
                title: transport.title(),
                icon: "profile_fields_transport"
            ))
        }
        
        if let title = profile.education, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_education"
            ))
        }
        
        if let rawValue = profile.educationLevel.value, let level = EducationLevel(rawValue: rawValue), level != .unknown {
            rows.append(ProfileFileRow(
                title: level.title(),
                icon: "profile_fields_education"
            ))
        }
        
        if let title = profile.tikTok, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "TikTok: " +  title,
                icon: "profile_fields_tiktok"
            ))
        }
        
        if let title = profile.instagram, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "Instagram: " +  title,
                icon: "profile_fields_instagram"
            ))
        }
        
        return rows
    }
    
    func leftUserColumnsFemale(_ profile: UserProfile) -> [ProfileFileRow]
    {
        var rows: [ProfileFileRow] = []
        
        if let title = profile.tikTok, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "TikTok: " + title,
                icon: "profile_fields_tiktok"
            ))
        }
        
        if let title = profile.instagram, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: "Instagram: " + title,
                icon: "profile_fields_instagram"
            ))
        }
        
        if let rawValue = profile.children.value, let children = Children(rawValue: rawValue), children != .unknown {
            rows.append(ProfileFileRow(
                title: children.title(),
                icon: "profile_fields_children"
            ))
        }
        
        if let rawValue = profile.educationLevel.value, let level = EducationLevel(rawValue: rawValue), level != .unknown {
            rows.append(ProfileFileRow(
                title: level.title(),
                icon: "profile_fields_education"
            ))
        }
        
        if let title = profile.education, title != "unknown", !title.isEmpty {
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_education"
            ))
        }
        
        if let jobTitle = profile.jobTitle, jobTitle != "unknown", !jobTitle.isEmpty {
            var title = jobTitle
            
            if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty {
                title += ", \(companyTitle)"
            }
            
            rows.append(ProfileFileRow(
                title: title,
                icon: "profile_fields_job"
            ))
        } else if let companyTitle = profile.company, companyTitle != "unknown", !companyTitle.isEmpty  {
            rows.append(ProfileFileRow(
                title: companyTitle,
                icon: "profile_fields_job"
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
        
        if let rawValue = profile.transport.value, let transport = Transport(rawValue: rawValue), transport != .unknown {
            rows.append(ProfileFileRow(
                title: transport.title(),
                icon: "profile_fields_transport"
            ))
        }
        
        return rows
    }
}
