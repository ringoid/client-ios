//
//  IncomeTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

extension Income
{
    func title() -> String
    {
        switch self {
        case .unknown: return "profile_field_not_selected"
        case .low: return "profile_field_income_low"
        case .middle: return "profile_field_income_middle"
        case .high: return "profile_field_income_high"
        case .ultraHigh: return "profile_field_income_ultrahigh"
        }
    }
}
