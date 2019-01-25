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
}

class MainLMMViewModel
{
    let lmmManager: LMMManager
    let profileManager: UserProfileManager
    var likesYou: BehaviorRelay<[LMMProfile]> { return self.lmmManager.likesYou }
    var matches: BehaviorRelay<[LMMProfile]> { return self.lmmManager.matches }
    var messages: BehaviorRelay<[LMMProfile]> { return self.lmmManager.messages }
    
    init(_ input: MainLMMVMInput)
    {
        self.lmmManager = input.lmmManager
        self.profileManager = input.profileManager
    }
    
    func refresh() -> Observable<Void>
    {
        return self.lmmManager.refresh().flatMap({ [weak self] _ -> Observable<Void> in
            return self!.profileManager.refresh()
        })
    }
}
