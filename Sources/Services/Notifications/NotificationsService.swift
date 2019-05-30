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
    var isEveningEnabled: BehaviorRelay<Bool> { get }
    var isLikeEnabled: BehaviorRelay<Bool> { get }
    var isMatchEnabled: BehaviorRelay<Bool> { get }
    var isMessageEnabled: BehaviorRelay<Bool> { get }
    var isRegistered: Bool { get }
    var responses: Observable<UNNotificationResponse>! { get }
    var notificationData: Observable<[AnyHashable : Any]>! { get }
    
    func handle(notificationDict: [AnyHashable : Any])
    func register()
    func update()
    func store(_ token: Data)
}
