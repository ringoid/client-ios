//
//  ProfileFieldType.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum ProfileFieldType: Int {
    case height = 0
    case hair = 1
    case education = 2
}

extension ProfileFieldType
{
    static func fieldsCount() -> Int { return 3 }
}
