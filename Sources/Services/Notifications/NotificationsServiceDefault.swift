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
import Firebase

class NotificationsServiceDefault: NSObject, NotificationService
{
    var notification: BehaviorRelay<RemoteNotification> = BehaviorRelay<RemoteNotification>(value: RemoteNotification(message: ""))
    var token: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    var isGranted: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var isEveningEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var isLikeEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var isMatchEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var isMessageEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var responses: Observable<UNNotificationResponse>!
    var foregroundNotifications: Observable<UNNotification>!
    var isRegistered: Bool = false
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var responseObserver: AnyObserver<UNNotificationResponse>?
    fileprivate var foregoundNotificationsObserver: AnyObserver<UNNotification>?
    
    override init()
    {
        super.init()
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        self.isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        
        self.loadStored()
        self.setupBindings()
        self.checkAndRegister()
        
        self.responses =  Observable<UNNotificationResponse>.create({ [weak self] observer -> Disposable in
            
            self?.responseObserver = observer
            
            return Disposables.create()
        })
        
        self.foregroundNotifications = Observable<UNNotification>.create({ [weak self] observer -> Disposable in
            
            self?.foregoundNotificationsObserver = observer
            
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
    
    func update()
    {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in            
            self?.isGranted.accept(settings.authorizationStatus == .authorized)
        }
    }
    
    func store(_ token: Data)
    {
        Messaging.messaging().apnsToken = token
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.isEveningEnabled.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "is_evening_enabled")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        self.isLikeEnabled.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "is_like_enabled")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        self.isMatchEnabled.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "is_match_enabled")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        self.isMessageEnabled.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "is_message_enabled")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func checkAndRegister()
    {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard settings.authorizationStatus != .notDetermined else { return }
            
            self?.register()
        }
    }
    
    fileprivate func loadStored()
    {
        if let storedToken = UserDefaults.standard.string(forKey: "push_token") {
            self.token.accept(storedToken)
        }
        
        if UserDefaults.standard.object(forKey: "is_evening_enabled") != nil {
            self.isEveningEnabled.accept(UserDefaults.standard.bool(forKey: "is_evening_enabled"))
        }
        
        if UserDefaults.standard.object(forKey: "is_like_enabled") != nil {
            self.isLikeEnabled.accept(UserDefaults.standard.bool(forKey: "is_like_enabled"))
        }
        
        if UserDefaults.standard.object(forKey: "is_match_enabled") != nil {
            self.isMatchEnabled.accept(UserDefaults.standard.bool(forKey: "is_match_enabled"))
        }
        
        if UserDefaults.standard.object(forKey: "is_message_enabled") != nil {
            self.isMessageEnabled.accept(UserDefaults.standard.bool(forKey: "is_message_enabled"))
        }
    }
}

extension NotificationsServiceDefault: UNUserNotificationCenterDelegate
{
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        AnalyticsManager.shared.send(.openedByPush)
        self.responseObserver?.onNext(response)
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        guard UIApplication.shared.applicationState == .active else { return }
        
        self.foregoundNotificationsObserver?.onNext(notification)
    }
}

extension NotificationsServiceDefault: MessagingDelegate
{
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String)
    {
        self.token.accept(fcmToken)
        UserDefaults.standard.set(fcmToken, forKey: "push_token")
        UserDefaults.standard.synchronize()
    }
}
