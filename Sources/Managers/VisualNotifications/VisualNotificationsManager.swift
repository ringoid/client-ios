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
        
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.notifications.notificationData.observeOn(MainScheduler.instance).subscribe(onNext:{ [weak self] userInfo in
            self?.handleRemoteNotification(userInfo)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func handleRemoteNotification(_ userInfo: [AnyHashable: Any])
    {
           guard let typeStr = userInfo["type"] as? String else { return }
           guard let remoteFeed = RemoteFeedType(rawValue: typeStr) else { return }
           guard let profileId = userInfo["oppositeUserId"] as? String else { return }
           guard !self.db.isBlocked(profileId) else { return }
    
           guard ChatViewController.openedProfileId != profileId else { return }
                
            guard let profile = self.lmm.profile(profileId) else {
                self.lmm.updateChat(profileId).observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                    self?.handleRemoteNotification(userInfo)
                }).disposed(by: self.disposeBag)
                
                return
            }
                   
           switch remoteFeed {
           case .likesYou:
               break
               
           case .matches:
               guard !self.lmm.messages.value.map({ $0.id }).contains(profileId) else { return }
               
               let item = VisualNotificationInfo(
                profileId: profileId,
                name: "No name yet",
                text: "New match",
                photoImage: nil,
                photoUrl: profile.photos.first?.filepath().url()
               )
               
               self.items.accept([item])
               
               break
                               
           case .messages:
                let item = VisualNotificationInfo(
                 profileId: profileId,
                 name: "No name yet",
                 text: "New messages",
                 photoImage: nil,
                 photoUrl: profile.photos.first?.filepath().url()
                )
                
                self.items.accept([item])
            
               break

           default: return
           }
    }
}

