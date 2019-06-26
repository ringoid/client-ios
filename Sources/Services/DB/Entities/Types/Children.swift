//
//  Children.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum Children: Int
{
    case unknown = 0
    case someday = 10
    case dontWant = 20
    case haveAndWant = 30
    case haveAndDontWant = 40
}

extension Children
{
    static func at(_ index: Int) -> Children {
        return Children(rawValue: index * 10)!
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
