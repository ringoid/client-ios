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
    fileprivate var isReadCache: [String: Bool] = [:]
    
    deinit
    {
        self.updateTimer?.invalidate()
        self.updateTimer = nil
    }
    
    init(_ input: ChatVMInput)
    {
        self.input = input
        
        self.setupBindings()
        self.input.lmmManager.updateChat(self.input.profile.id).subscribe().disposed(by: self.disposeBag)
    }
    
    func send(_ text: String)
    {
        self.markAsRead()
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
        self.input.lmmManager.updateChat(self.input.profile.id).subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        Observable.collection(from: self.input.profile.messages).subscribe(onNext: { [weak self] updatedMessages in
            guard let `self` = self else { return }
            
            let updatedMessagesArray = updatedMessages.toArray()
            guard self.isContentUpdated(updatedMessagesArray) else { return }
            
            self.messages.accept(updatedMessagesArray)
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
        defer {
            updatedMessages.forEach({ self.isReadCache[$0.id] = $0.isRead })
        }
        
        for message in updatedMessages
        {
            if let isRead = self.isReadCache[message.id] {
                if isRead != message.isRead { return true }
            } else {
                return true
            }
        }
        
        return false 
    }
}
