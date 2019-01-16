
//
//  NewFacesViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct NewFacesVMInput
{
    let newFacesManager: NewFacesManager
    let actionsManager: ActionsManager
}

class NewFacesViewModel
{
    let newFacesManager: NewFacesManager
    
    var profiles: BehaviorRelay<[NewFaceProfile]> { return self.newFacesManager.profiles }
    
    init(_ input: NewFacesVMInput)
    {
        self.newFacesManager = input.newFacesManager
    }
    
    func refresh() -> Observable<Void>
    {
        return self.newFacesManager.refresh()
    }
}
