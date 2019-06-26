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
            
        case .children:
            guard let index = index else { return }
            
            self.db.write {
                profile.children.value = Children.at(index).rawValue
            }
            break
            
        case .transport:
            guard let index = index else { return }
            
            self.db.write {
                profile.transport.value = Transport.at(index).rawValue
            }
            break
            
        case .income:
            guard let index = index else { return }
            
            self.db.write {
                profile.income.value = Income.at(index).rawValue
            }
            break
            
        case .education:
            guard let text = value else { return }
            
            self.db.write {
                profile.education = text
            }
            break
            
        case .name:
            guard let text = value else { return }
            
            self.db.write {
                profile.name = text
            }
            break
            
        case .tiktok:
            guard let text = value else { return }
            
            self.db.write {
                profile.tikTok = text
            }
            break
            
        case .instagram:
            guard let text = value else { return }
            
            self.db.write {
                profile.instagram = text
            }
            break
            
        case .whereLive:
            guard let text = value else { return }
            
            self.db.write {
                profile.whereLive = text
            }
            break
            
        case .bio:
            guard let text = value else { return }
            
            self.db.write {
                profile.about = text
            }
            break
            
        case .company:
            guard let text = value else { return }
            
            self.db.write {
                profile.company = text
            }
            break
            
        case .job:
            guard let text = value else { return }
            
            self.db.write {
                profile.jobTitle = text
            }
            break
            
        case .property:
            guard let index = index else { return }
            
            self.db.write {
                profile.property.value = Property.at(index).rawValue
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
