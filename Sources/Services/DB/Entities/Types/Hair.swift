//
//  Hair.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum Hair: Int {
    case unknown = 0
    case black = 10
    case blonde = 20
    case brown = 30
    case red = 40
    case gray = 50
    case white = 60
}

extension Hair
{
    static func value(_ index: Int) -> Int
    {
        return index * 10
    }
    
    static func count() -> Int { return 6 }
    
    func index() -> Int
    {
        return self.rawValue / 10
    }
}
