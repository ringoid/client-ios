//
//  NewFacesFilterViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 19/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

struct NewFacesFilterVMInput
{
    let filter: FilterManager
}

class NewFacesFilterViewModel
{
    let filter: FilterManager
    
    init(_ input: NewFacesFilterVMInput)
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
