//
//  NotificationsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class NotificationsManager
{
    let notifications: NotificationService
    let api: ApiService
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ notifications: NotificationService, api: ApiService)
    {
        self.notifications = notifications
        self.api = api
        
        self.setupBindings()
    }
    
    func updateFCMToken()
    {
        self.notifications.senderId.accept(AppConfig.fcmSenderId)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.notifications.token.asObservable().subscribe(onNext: { [weak self] token in
            guard let token = token else { return }
            guard let `self` = self else { return }
            guard self.api.isAuthorized.value else { return }
            
            log("FCM TOKEN: \(token)", level: .high)
            self.api.updatePush(token).subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
        
        self.notifications.notificationData.subscribe(onNext: { _ in
            print("PUSH RECEIVED")
        }).disposed(by: self.disposeBag)
        
        self.api.customerId.asObservable().subscribe(onNext: { [weak self] _ in
            self?.updateFCMToken()
        }).disposed(by: self.disposeBag)
        
        self.notifications.isGranted.subscribe(onNext:{ [weak self] state in
            guard state else { return }
            
            self?.updateFCMToken()
        }).disposed(by: self.disposeBag)
    }
}
