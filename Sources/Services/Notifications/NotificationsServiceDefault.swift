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
    var token: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    var isGranted: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var responses: Observable<UNNotificationResponse>!
    var isRegistered: Bool = false
    
    fileprivate var responseObserver: AnyObserver<UNNotificationResponse>?
    
    override init()
    {
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
        self.isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        self.checkAndRegister()
        
        
        self.responses =  Observable<UNNotificationResponse>.create({ [weak self] observer -> Disposable in
            
            self?.responseObserver = observer
            
            return Disposables.create()
        })
        
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
            self?.isGranted.accept(granted)
            
            if error != nil || !granted
            {
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
                self?.isGranted.accept(granted)
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
        self.responseObserver?.onNext(response)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        
    }
}
