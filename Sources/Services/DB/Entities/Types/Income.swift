//
//  Income.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum Income: Int
{
    case unknown = 0
    case low = 10
    case middle = 20
    case high = 30
    case ultraHigh = 40
}

extension Income
{
    static func at(_ index: Int) -> Income {
        return Income(rawValue: index * 10)!
    }
    
    static func count() -> Int
    {
        return 5
    }
    
    func index() -> Int
    {
        return self.rawValue / 10
    }
}
