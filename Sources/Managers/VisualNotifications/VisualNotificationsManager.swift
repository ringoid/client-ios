//
//  VisualNotificationsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 26/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class VisualNotificationsManager
{
    var items: BehaviorRelay<[VisualNotificationInfo]> = BehaviorRelay<[VisualNotificationInfo]>(value: [])
    
    fileprivate let notifications: NotificationService
    fileprivate let db: DBService
    fileprivate let lmm: LMMManager
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ notifications: NotificationService, db: DBService, lmm: LMMManager)
    {
        self.notifications = notifications
        self.db = db
        self.lmm = lmm
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.notifications.notificationData.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] userInfo in
                   guard let `self` = self else { return }
                   
                   guard let typeStr = userInfo["type"] as? String else { return }
                   guard let remoteFeed = RemoteFeedType(rawValue: typeStr) else { return }
                   guard let profileId = userInfo["oppositeUserId"] as? String else { return }
                   guard !self.db.isBlocked(profileId) else { return }
            
                   guard ChatViewController.openedProfileId != profileId else { return }
                   
                   switch remoteFeed {
                   case .likesYou:
                       break
                       
                   case .matches:
                       guard !self.lmm.messages.value.map({ $0.id }).contains(profileId) else { return }
                       
                       let item = VisualNotificationInfo(
                        profileId: profileId,
                        text: "New match",
                        photoImage: nil,
                        photoUrl: nil
                       )
                       
                       var currentItems = self.items.value
                       currentItems.insert(item, at: 0)
                       self.items.accept(currentItems)
                       
                       break
                                       
                   case .messages:
                        let item = VisualNotificationInfo(
                         profileId: profileId,
                         text: "New messages",
                         photoImage: nil,
                         photoUrl: nil
                        )
                        
                        var currentItems = self.items.value
                        currentItems.insert(item, at: 0)                        
                        self.items.accept(currentItems)
                    
                       break
        
                   default: return
                   }
                   
               }).disposed(by: self.disposeBag)
    }
}

