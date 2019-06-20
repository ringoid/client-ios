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
    let source: SourceFeedType
    let chatManager: ChatManager
    let lmmManager: LMMManager
    let scenario: AnalyticsScenarioManager
    let transition: TransitionManager
    let onClose: (()->())?
    let onBlock: (()->())?
}

class ChatViewModel
{
    let input: ChatVMInput
    
    let messages: BehaviorRelay<[Message]> = BehaviorRelay<[Message]>(value: [])
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var updateTimer: Timer?
    
    deinit
    {
        self.updateTimer?.invalidate()
        self.updateTimer = nil
    }
    
    init(_ input: ChatVMInput)
    {
        self.input = input
        
        self.setupBindings()
        self.input.lmmManager.updateChat(self.input.profile.id)
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
        self.input.lmmManager.removeNotificationFromProcessed(self.input.profile.id)
    }
    
    func updateContent()
    {
        self.input.lmmManager.updateChat(self.input.profile.id)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.profile.rx.observe(LMMProfile.self, "messages").subscribe(onNext: { [weak self] _ in
            guard let updatedProfile = self?.input.profile else { return }
            
            self?.messages.accept(Array(updatedProfile.messages.sorted(byKeyPath: "orderPosition")))
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.chatUpdateInterval.observeOn(MainScheduler.instance).subscribe(onNext:{ [weak self] interval in
            self?.updateTimer?.invalidate()
            self?.updateTimer = nil
            
            let timer = Timer(timeInterval: interval, repeats: true, block: { _ in
                self?.updateContent()
            })
            RunLoop.main.add(timer, forMode: .common)
            self?.updateTimer = timer
        }).disposed(by: self.disposeBag)
    }
}
