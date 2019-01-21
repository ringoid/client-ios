
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
    var profiles: BehaviorRelay<[NewFaceProfile]> { return self.newFacesManager.profiles }
    var isFetching: Bool = false
    
    let newFacesManager: NewFacesManager
    
    init(_ input: NewFacesVMInput)
    {
        self.newFacesManager = input.newFacesManager
    }
    
    func refresh() -> Observable<Void>
    {
        return self.newFacesManager.refresh()
    }
    
    func fetchNext() -> Observable<Void>
    {
        guard !self.isFetching else {
            let error = createError("New faces fetching in already in progress", type: .hidden)
            
            return .error(error)
        }
        
        self.isFetching = true
        return self.newFacesManager.fetch()
    }
    
    func finishFetching()
    {
        self.isFetching = false
    }
}
