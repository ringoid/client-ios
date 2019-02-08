
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
    let navigationManager: NavigationManager
}

class NewFacesViewModel
{
    var profiles: BehaviorRelay<[NewFaceProfile]> { return self.newFacesManager.profiles }
    var isFetching: Bool = false
    var isPhotosAdded: Bool
    {
        return !self.profileManager.photos.value.isEmpty
    }
    
    let newFacesManager: NewFacesManager
    let profileManager: UserProfileManager
    let navigationManager: NavigationManager
    let actionsManager: ActionsManager
    
    init(_ input: NewFacesVMInput)
    {
        self.newFacesManager = input.newFacesManager
        self.profileManager = input.profileManager
        self.navigationManager = input.navigationManager
        self.actionsManager = input.actionsManager
    }
    
    func refresh() -> Observable<Void>
    {
        self.actionsManager.commit()
        
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
    
    func moveToProfile()
    {
        self.navigationManager.mainItem.accept(.profile)
    }
}
