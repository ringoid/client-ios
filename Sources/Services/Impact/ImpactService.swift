//
//  ImpactService.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum ImpactType
{
    case light;
    case medium;
    case heavy;
}

protocol ImpactService
{
    func perform(_ type: ImpactType)
}
