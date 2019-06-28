//
//  ChildrenTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

extension Children
{
    func title() -> String
    {
        switch self {
        case .unknown: return "profile_field_not_selected"
        case .someday: return "profile_field_children_someday"
        case .dontWant: return "profile_field_children_dont_want"
        case .haveAndWant: return "profile_field_children_have_want"
        case .haveAndDontWant: return "profile_field_children_have_dont_want"
        }
    }
}
