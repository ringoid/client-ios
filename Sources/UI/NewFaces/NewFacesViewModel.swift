
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
    let profileManager: UserProfileManager
    let lmmManager: LMMManager
    let navigationManager: NavigationManager
}

class NewFacesViewModel
{
    var profiles: BehaviorRelay<[NewFaceProfile]> { return self.newFacesManager.profiles }
    var isFetching : BehaviorRelay<Bool> { return self.newFacesManager.isFetching }
    
    let newFacesManager: NewFacesManager
    let profileManager: UserProfileManager
    let navigationManager: NavigationManager
    let actionsManager: ActionsManager
    let lmmManager: LMMManager
    
    init(_ input: NewFacesVMInput)
    {
        self.newFacesManager = input.newFacesManager
        self.profileManager = input.profileManager
        self.navigationManager = input.navigationManager
        self.actionsManager = input.actionsManager
        self.lmmManager = input.lmmManager
    }
    
    func refresh() -> Observable<Void>
    {
        self.isFetching.accept(true)
        self.profileManager.refreshInBackground()
        self.actionsManager.finishViewActions(for: self.profiles.value, source: .newFaces)
        
        return self.actionsManager.sendQueue().flatMap({ [weak self] _ -> Observable<Void> in
            self!.lmmManager.refreshInBackground(.newFaces)
            
            return self!.newFacesManager.refresh()
        })
    }
    
    func fetchNext() -> Observable<Void>
    {
        guard !self.isFetching.value else {
            let error = createError("New faces fetching in already in progress", type: .hidden)
            
            return .error(error)
        }
  
        self.isFetching.accept(true)
        
        return self.actionsManager.sendQueue().flatMap { [weak self] _ -> Observable<Void> in
            guard let `self` = self else { return .just(()) } // view model deleted
            
            return self.newFacesManager.fetch()
        }
    }
    
    func moveToProfile()
    {
        self.navigationManager.mainItem.accept(.profileAndPick)
    }
}
