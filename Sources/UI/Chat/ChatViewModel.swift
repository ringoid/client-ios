//
//  ChatViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct ChatVMInput
{
    let profile: LMMProfile
    let actionsManager: ActionsManager
    let onClose: (()->())?
}

class ChatViewModel
{
    let input: ChatVMInput
    
    let messages: BehaviorRelay<[Message]> = BehaviorRelay<[Message]>(value: [])
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ input: ChatVMInput)
    {
        self.input = input
        
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.profile.rx.observe(LMMProfile.self, "messages").subscribe(onNext: { [weak self] _ in
            guard let updatedProfile = self?.input.profile else { return }
            
            self?.messages.accept(Array(updatedProfile.messages))
        }).disposed(by: self.disposeBag)
    }
}
