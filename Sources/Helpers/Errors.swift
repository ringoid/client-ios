//
//  Errors.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum ErrorType: Int
{
    case hidden = 0
    case visible = 1
    case api = 2
    case wrongParams = 3
}

func createError(_ description: String, type: ErrorType) -> Error
{
    return NSError(domain: "com.ringoid.ringoid", code: type.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
}
