//
//  SettingsFilterViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/07/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxCocoa
import RxSwift

struct SettingsFilterVMInput
{
    let filter: FilterManager
    let lmm: LMMManager
    let newFaces: NewFacesManager
}

class SettingsFilterViewModel
{
    let filter: FilterManager
    let lmm: LMMManager
    let newFaces: NewFacesManager
    
    init(_ input: SettingsFilterVMInput)
    {
        self.filter = input.filter
        self.lmm = input.lmm
        self.newFaces = input.newFaces
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
    
    func updateFeeds()
    {
        self.lmm.refreshInBackground(.profile)
        self.newFaces.refreshInBackground()
    }
}
