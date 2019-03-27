//
//  NotificationsServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/03/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UserNotifications
import RxSwift
import RxCocoa

class NotificationsServiceDefault: NSObject, NotificationService
{
    var notification: BehaviorRelay<RemoteNotification> = BehaviorRelay<RemoteNotification>(value: RemoteNotification(message: ""))
    var token: String? = nil
    var isRegistered: Bool = false
    var isGranted: Bool = false
    
    override init()
    {
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
        self.isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        self.checkAndRegister()
    }
    
    func update(token: String)
    {
        self.token = token
    }
    
    func handle(notificationDict: [AnyHashable : Any])
    {
        log("Received push", level: .high)
        print(notificationDict)
    }
    
    func register()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [ .badge, .alert, .sound ]) { [weak self] (granted, error) in
            self?.isRegistered = true
            self?.isGranted = granted
            
            if error != nil || !granted
            {
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    // MARK: -
    
    func checkAndRegister()
    {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus != .notDetermined else { return }
            
            self?.register()
        }
    }
}

extension NotificationsServiceDefault: UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        
    }
}
