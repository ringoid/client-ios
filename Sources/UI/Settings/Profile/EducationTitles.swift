//
//  EducationTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

extension EducationLevel
{
    func title() -> String
    {
        switch self {
        case .unknown: return "profile_field_not_selected"
        case .school: return "profile_field_education_school"
        case .college: return "profile_field_education_college"
        case .university1: return "profile_field_education_university1"
        case .university2: return "profile_field_education_university2"
        case .university3: return "profile_field_education_university3"
        case .postGrad: return "profile_field_education_postgrad"
        }
    }
}
