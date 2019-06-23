//
//  HairTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

//case black = 10
//case blonde = 20
//case brown = 30
//case red = 40
//case gray = 50
//case white = 60

extension Hair
{
    func title(_ sex: Sex) -> String
    {
        if sex == .male {
            switch self {
            case .unknown: return ""
            case .black: return "profile_field_hair_black_male"
            case .blonde: return "profile_field_hair_blonde_male"
            case .brown: return "profile_field_hair_brown_male"
            case .red: return "profile_field_hair_red_male"
            case .gray: return "profile_field_hair_gray_male"
            case .white: return "profile_field_hair_white_male"
            }
        }
        
        if sex == .female {
            switch self {
            case .unknown: return ""
            case .black: return "profile_field_hair_black_female"
            case .blonde: return "profile_field_hair_blonde_female"
            case .brown: return "profile_field_hair_brown_female"
            case .red: return "profile_field_hair_red_female"
            case .gray: return "profile_field_hair_gray_female"
            case .white: return "profile_field_hair_white_female"
            }
        }
        
        return ""
    }
}
