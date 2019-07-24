//
//  MainLCFilterViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

struct MainLCFilterVMInput
{
    let filter: FilterManager
    let lmm: LMMManager
    let feedType: LMMType
}

class MainLCFilterViewModel
{
    let filter: FilterManager
    
    init(_ input: MainLCFilterVMInput)
    {
        self.filter = input.filter
    }
    
    var minAge: BehaviorRelay<Int?>
    {
        return self.filter.minAge
    }
    
    var maxAge: BehaviorRelay<Int?>
    {
        return self.filter.maxAge
    }
    
    var maxDistance: BehaviorRelay<Int?>
    {
        return self.filter.maxDistance
    }
}
