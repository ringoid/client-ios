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
        if index == 0 { return "profile_field_not_selected".localized() }
        
        let feet: Double = 3.0 + 4.0 / 40.0 * Double(index)
        let cm: Int = Int(feet * 30.48)
        let feetFirst: Int = Int(feet)
        let feetSecond: Int = Int((feet - Double(feetFirst)) * 10.0)
        
        return "\(feetFirst)'\(feetSecond) (\(cm) cm)"
    }
    
    static func value(_ index: Int) -> Int
    {
        guard index != 0 else { return 0 }
        
        let feet: Double = 3.0 + 4.0 / 40.0 * Double(index)
        return Int(feet * 30.48)
    }
    
    static func count() -> Int
    {
        return 41
    }
}

func heightIndex(_ value: Int) -> Int
{
    guard value != 0 else { return 0 }
    
    return Int((Double(value) - 91.0) / 3.0)
}
