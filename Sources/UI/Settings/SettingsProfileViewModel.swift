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
    let db: DBService
}

class SettingsProfileViewModel
{
    let configuration: ProfileFieldsConfiguration
    let profileManager: UserProfileManager
    let db: DBService
    
    init(_ input: SettingsProfileVMInput)
    {
        self.configuration = ProfileFieldsConfiguration(input.profileManager)
        self.profileManager = input.profileManager
        self.db = input.db
        
        self.checkProfile()
    }
    
    func updateField(_ type: ProfileFieldType, index: Int?, value: String?)
    {
        guard let profile = self.profileManager.profile.value else { return }
        
        switch type {
            
        case .height:
            guard let index = index else { return }
            
            self.db.write {
                profile.height.value = Height.value(index)
            }
            break
            
        case .hair:
            guard let index = index else { return }
            
            self.db.write {
                profile.hairColor.value = Hair.value(index)
            }
            break
            
        case .educationLevel:
            guard let index = index else { return }
            
            self.db.write {
                profile.educationLevel.value = EducationLevel.at(index, locale: LocaleManager.shared.language.value).rawValue
            }
            break
            
        case .education:
            guard let text = value else { return }
            
            self.db.write {
                profile.education = text
            }
            break
        }
    }
    
    // MARK: -
    
    fileprivate func checkProfile()
    {
        if self.profileManager.profile.value == nil {
            self.profileManager.createProfile()
        }
    }
}
