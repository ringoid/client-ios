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
    let actions: ActionsManager
    let onClose: (()->())?
    let onBlock: (()->())?
}

class ChatViewModel
{
    let input: ChatVMInput
    
    let messages: BehaviorRelay<[Message]> = BehaviorRelay<[Message]>(value: [])
    
    var activeSendingActions: Observable<[String]>
    {
        return self.input.actions.activeSendingActions()
    }
    
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
            guard let `self` = self else { return }

            let updatedMessages = self.input.profile.messages.toArray()
            guard self.isContentUpdated(updatedMessages) else { return }
            
            self.messages.accept(updatedMessages)
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
    
    fileprivate func isContentUpdated(_ updatedMessages: [Message]) -> Bool
    {
        let localMessages = self.messages.value
        
        guard updatedMessages.count != 0 else { return false }
        guard localMessages.count == updatedMessages.count else { return true }
        
        for (i, localMessage) in localMessages.enumerated() {
            let updatedMessage = updatedMessages[i]
            
            if localMessage.id != updatedMessage.id { return true }
            if localMessage.isRead != updatedMessage.isRead { return true }
        }
        
        return false
    }
}
