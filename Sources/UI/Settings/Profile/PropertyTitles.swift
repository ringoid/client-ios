//
//  PropertyTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

extension Property
{
    func title() -> String
    {
        switch self {
        case .unknown: return "profile_field_not_selected"
        case .parents: return "profile_field_property_parents"
        case .dormitory: return "profile_field_property_dormitory"
        case .friend: return "profile_field_property_friend"
        case .room: return "profile_field_property_room"
        case .flat: return "profile_field_property_flat"
        case .house: return "profile_field_property_house"
        }
    }
}
