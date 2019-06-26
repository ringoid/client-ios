//
//  Transport.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum Transport: Int
{
    case unknown = 0
    case walk = 10
    case publicTransport = 20
    case cycle = 30
    case motocycle = 40
    case car = 50
    case taxi = 60
    case chauffeur = 70
}

extension Transport
{
    static func at(_ index: Int) -> Transport {
        return Transport(rawValue: index * 10)!
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
