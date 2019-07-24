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
    let lmm: LMMManager
    let type: LMMType
    
    init(_ input: MainLCFilterVMInput)
    {
        self.filter = input.filter
        self.lmm = input.lmm
        self.type = input.feedType
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
    
    func update()
    {
        self.lmm.updateFilterCounters(self.type.sourceType())
    }
}
