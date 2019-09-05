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
    var senderId: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    var notification: BehaviorRelay<RemoteNotification> = BehaviorRelay<RemoteNotification>(value: RemoteNotification(message: ""))
    var token: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    var isGranted: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var isEveningEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var isLikeEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var isMatchEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var isMessageEnabled: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    var responses: Observable<UNNotificationResponse>!
    var notificationData: Observable<[AnyHashable : Any]>!
    var isRegistered: Bool = false
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var responseObserver: AnyObserver<UNNotificationResponse>?
    fileprivate var notificationDataObserver: AnyObserver<[AnyHashable : Any]>?
    fileprivate var isGrantedPrevState: Bool = true
    
    override init()
    {
        super.init()
        
        //Messaging.messaging().delegate = self
        Messaging.messaging().isAutoInitEnabled = false
        
        UNUserNotificationCenter.current().delegate = self
        self.isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        
        self.loadStored()
        self.setupBindings()
        self.checkAndRegister()
        
        self.responses =  Observable<UNNotificationResponse>.create({ [weak self] observer -> Disposable in
            
            self?.responseObserver = observer
            
            return Disposables.create()
        })
        
        self.notificationData = Observable<[AnyHashable : Any]>.create({ [weak self] observer -> Disposable in
            
            self?.notificationDataObserver = observer
            
            return Disposables.create()
        }).share()
        
    }
    
    func handle(notificationDict: [AnyHashable : Any])
    {
        self.notificationDataObserver?.onNext(notificationDict)
    }
    
    func register()
    {
        UNUserNotificationCenter.current().requestAuthorization(options: [ .badge, .alert, .sound ]) { [weak self] (granted, error) in
            defer {
                self?.isGrantedPrevState = granted
            }
            
            self?.isRegistered = true
            self?.isGranted.accept(granted)
            
            if error != nil || !granted
            {
                return
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func update()
    {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let state = settings.authorizationStatus == .authorized
            self?.isGranted.accept(state)
            
            defer {
                self?.isGrantedPrevState = state
            }
            
            guard state else { return }
            
            if self?.isGrantedPrevState == false {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func store(_ token: Data)
    {
        Messaging.messaging().setAPNSToken(token, type: .unknown)

        if let senderId = self.senderId.value {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.updateFCMToken(senderId)
            }
        }
    }
    
    func updateFCMToken(_ senderId: String)
    {
        guard Messaging.messaging().apnsToken != nil else { return }
        
        log("Updating FCM token...", level: .low)
        
        Messaging.messaging().deleteFCMToken(forSenderID: senderId) { [weak self] _ in
            Messaging.messaging().retrieveFCMToken(forSenderID: senderId) {  (fcmToken, error) in
                if let error = error {
                    log("FCM token error: \(error)", level: .high)
                    
                    return
                }
                
                self?.token.accept(fcmToken)
            }
        }
    }
    
    func reset()
    {
        guard let senderId = self.senderId.value else { return }
        
        self.deleteFCMToken(senderId)
        self.senderId.accept(nil)
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
        
        self.senderId.asObservable().subscribe(onNext: { [weak self] id in
            guard let senderId = id else { return }
            
            self?.updateFCMToken(senderId)
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
    
    fileprivate func deleteFCMToken(_ senderId: String)
    {
        Messaging.messaging().deleteFCMToken(forSenderID: senderId) { _ in
            
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
        
        self.notificationDataObserver?.onNext(notification.request.content.userInfo)
    }
}
