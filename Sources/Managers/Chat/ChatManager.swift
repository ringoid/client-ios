//
//  ChatManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 25/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class ChatManager
{
    let db: DBService
    let actionsManager: ActionsManager
    let scenario: AnalyticsScenarioManager
    let lastSentProfileId: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, actionsManager: ActionsManager, scenario: AnalyticsScenarioManager)
    {
        self.db = db
        self.actionsManager = actionsManager
        self.scenario = scenario
    }
    
    func send(_ text: String, profile: LMMProfile, photo: Photo, source: SourceFeedType)
    {
        self.scenario.checkFirstMessageSent(source)
        
        let messageId = UUID().uuidString
        
        let message = Message()
        message.id = messageId
        message.text = text
        message.wasYouSender = true
        message.timestamp = Date()
        message.isRead = true
        message.msgId = ""
        
        self.db.lmmDuplicates(profile.id).subscribe(onSuccess: { profiles in
            profiles.forEach {
                $0.write { obj in
                    let lmmProfile = obj as? LMMProfile
                    let duplicateMessage = message.duplicate()
                    duplicateMessage.orderPosition = lmmProfile?.messages.sorted(byKeyPath: "orderPosition").last?.orderPosition ?? 0
                    lmmProfile?.messages.append(duplicateMessage)
                }
                
                self.db.forceMark($0, isSeen: true)
            }
        }).disposed(by: self.disposeBag)
        

        let photoId = photo.id
        guard let actionProfile = profile.actionInstance(), let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first else { return }
        
        self.actionsManager.messageActionProtected(
            messageId,
            text: text,
            profile: actionProfile,
            photo: actionPhoto,
            source: source
        )
        
        self.lastSentProfileId.accept(profile.id)
    }
    
    func markAsRead(_ profile: LMMProfile)
    {
        profile.messages.forEach({ message in
            guard !message.wasYouSender else { return }
            guard !message.isRead else { return }
            
            self.actionsManager.markMessageRead(message.msgId, oppositeUserId: profile.id)
            self.db.write({
                message.isRead = true
            })
        })
        
        // Marking as seen
        self.db.lmmDuplicates(profile.id).subscribe(onSuccess: { [weak self] duplicates in
            duplicates.forEach({ self?.db.forceMark($0, isSeen: true) })
            
        }).disposed(by: self.disposeBag)
        
        self.actionsManager.commit()
    }
}
