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
}

class MainLMMViewModel
{
    let lmmManager: LMMManager
    var likesYou: BehaviorRelay<[LMMProfile]> { return self.lmmManager.likesYou }
    var matches: BehaviorRelay<[LMMProfile]> { return self.lmmManager.matches }
    var messages: BehaviorRelay<[LMMProfile]> { return self.lmmManager.messages }
    
    init(_ input: MainLMMVMInput)
    {
        self.lmmManager = input.lmmManager
    }
    
    func refresh() -> Observable<Void>
    {
        return self.lmmManager.refresh()
    }
}
