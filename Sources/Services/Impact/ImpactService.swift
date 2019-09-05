//
//  ImpactService.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

enum ImpactType
{
    case light;
    case medium;
    case heavy;
}

protocol ImpactService
{
    var isEnabled: BehaviorRelay<Bool> { get set }
    var isAvailable: Bool { get }
    
    func perform(_ type: ImpactType)
    func reset()
}
