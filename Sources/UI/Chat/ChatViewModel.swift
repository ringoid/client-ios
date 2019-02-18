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
    let photo: Photo
    let chatManager: ChatManager
    let source: SourceFeedType
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
    
    func send(_ text: String)
    {
        self.input.chatManager.send(text,
                                    profile: self.input.profile,
                                    photo: self.input.photo,
                                    source: self.input.source
        )
    }
    
    func markAsRead()
    {
        self.input.chatManager.markAsRead(self.input.profile)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.profile.rx.observe(LMMProfile.self, "messages").subscribe(onNext: { [weak self] _ in
            guard let updatedProfile = self?.input.profile else { return }
            
            self?.messages.accept(Array(updatedProfile.messages.sorted(byKeyPath: "orderPosition")))
        }).disposed(by: self.disposeBag)
    }
}
