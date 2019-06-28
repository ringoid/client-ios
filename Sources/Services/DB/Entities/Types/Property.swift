//
//  Property.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum Property: Int
{
    case unknown = 0
    case parents = 10
    case dormitory = 20
    case friend = 30
    case room = 40
    case flat = 50
    case house = 60
}

extension Property
{
    static func at(_ index: Int) -> Property {
        return Property(rawValue: index * 10)!
    }
    
    static func count() -> Int
    {
        return 7
    }
    
    func index() -> Int
    {
        return self.rawValue / 10
    }
}
