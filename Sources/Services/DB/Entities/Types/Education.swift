//
//  Education.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum Education: Int
{
    case unknown = 0
    case school = 10
    case college = 20
    case university1 = 30
    case university2 = 40
    case university3 = 50
    case postGrad = 60
}

fileprivate let englishIndexMap: [Education] = [
    .unknown,
    .school,
    .college,
    .university2,
    .postGrad
]

fileprivate let indexMap: [Education] = [
    .unknown,
    .school,
    .college,
    .university1,
    .university2,
    .university3,
    .postGrad
]

extension Education
{
    static func at(_ index: Int, locale: Language) -> Education {
        if locale == .english { return englishIndexMap[index]}
        
        return indexMap[index]
    }
    
    static func count(_ locale: Language) -> Int
    {
        if locale == .english { return 5}
        
        return 7
    }
}

