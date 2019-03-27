//
//  NotificationsService.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct RemoteNotification
{
    let message: String
}

protocol NotificationService
{
    var notification: BehaviorRelay<RemoteNotification> { get }
    var token: String? { get }
    var isRegistered: Bool { get }
    var isGranted: Bool { get }
    
    func update(token: String)
    func handle(notificationDict: [AnyHashable : Any])
    func register()
}
