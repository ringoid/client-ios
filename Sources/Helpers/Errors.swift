//
//  Errors.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

func createError(_ description: String, code: Int) -> Error
{
    return NSError(domain: "com.ringoid.ringoid", code: code, userInfo: [NSLocalizedDescriptionKey: description])
}
