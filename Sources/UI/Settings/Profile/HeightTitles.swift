//
//  HeightTitles.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

class Height
{
    static func title(_ index: Int) -> String
    {
        let feet: Double = 3.0 + 4.0 / 40.0 * Double(index)
        let cm: Int = Int(feet * 30.48)
        let feetFirst: Int = Int(feet)
        let feetSecond: Int = Int((feet - Double(feetFirst)) * 10.0)
        
        return "\(feetFirst)'\(feetSecond) (\(cm) cm)"
    }
    
    static func count() -> Int
    {
        return 41
    }
}
