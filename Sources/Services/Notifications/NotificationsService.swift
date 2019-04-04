//
//  NotificationsService.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa
import UserNotifications

struct RemoteNotification
{
    let message: String
}

protocol NotificationService
{
    var notification: BehaviorRelay<RemoteNotification> { get }
    var token: BehaviorRelay<String?> { get }
    var isGranted: BehaviorRelay<Bool> { get }
    var isRegistered: Bool { get }
    var responses: Observable<UNNotificationResponse>! { get }
    
    func handle(notificationDict: [AnyHashable : Any])
    func register()
}
