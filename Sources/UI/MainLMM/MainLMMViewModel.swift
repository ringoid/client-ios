//
//  MainLMMViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct MainLMMVMInput
{
    let lmmManager: LMMManager
    let actionsManager: ActionsManager
    let chatManager: ChatManager
    let profileManager: UserProfileManager
    let navigationManager: NavigationManager
    let newFacesManager: NewFacesManager
}

class MainLMMViewModel
{
    let lmmManager: LMMManager
    let profileManager: UserProfileManager
    let actionsManager: ActionsManager
    let navigationManager: NavigationManager
    let newFacesManager: NewFacesManager
    
    var likesYou: BehaviorRelay<[LMMProfile]> { return self.lmmManager.likesYou }
    var matches: BehaviorRelay<[LMMProfile]> { return self.lmmManager.matches }
    var messages: BehaviorRelay<[LMMProfile]> { return self.lmmManager.messages }
    
    var isPhotosAdded: Bool
    {
        return !self.profileManager.photos.value.isEmpty
    }
    
    init(_ input: MainLMMVMInput)
    {
        self.lmmManager = input.lmmManager
        self.profileManager = input.profileManager
        self.actionsManager = input.actionsManager
        self.navigationManager = input.navigationManager
        self.newFacesManager = input.newFacesManager
    }
    
    func refresh() -> Observable<Void>
    {
        self.newFacesManager.purge()
        self.actionsManager.commit()
        
        return self.lmmManager.refresh().flatMap({ [weak self] _ -> Observable<Void> in
            return self!.profileManager.refresh()
        })
    }
    
    func moveToProfile()
    {
        self.navigationManager.mainItem.accept(.profileAndPick)
    }
}
