//
//  SettingsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class SettingsManager
{
    let db: DBService
    let api: ApiService
    let fs: FileService
    let storage: XStorageService
    let actions: ActionsManager
    let lmm: LMMManager
    let newFaces: NewFacesManager
    let notifications: NotificationService
    let scenario: AnalyticsScenarioManager
    let profile: UserProfileManager
    
    let isFirstLaunch: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    var customerId: BehaviorRelay<String>
    {
        return self.api.customerId
    }
    
    var isAuthorized: BehaviorRelay<Bool>
    {
        return self.api.isAuthorized
    }
    
    var isNotificationsAllowed: Bool
    {
        get {
            let allowedByUser = (UserDefaults.standard.object(forKey: "notificationsAllowedByUser") as? Bool) ?? true
            let allowedBySystem = self.notifications.isGranted.value
            
            return allowedByUser && allowedBySystem
        }
        
        set {
            log("App push setting updated: \(newValue)", level: .low)
            UserDefaults.standard.set(newValue, forKey: "notificationsAllowedByUser")
            UserDefaults.standard.synchronize()
        }
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(db: DBService, api: ApiService, fs: FileService, storage: XStorageService, actions: ActionsManager, lmm: LMMManager, newFaces: NewFacesManager, notifications: NotificationService, scenario: AnalyticsScenarioManager, profile: UserProfileManager)
    {
        self.db = db
        self.api = api
        self.fs = fs
        self.storage = storage
        self.actions = actions
        self.lmm = lmm
        self.newFaces = newFaces
        self.notifications = notifications
        self.scenario = scenario
        self.profile = profile
        
        self.loadSettings()
        self.updateRemoteSettings()
        self.setupBindings()
    }
    
    func updatePushToken()
    {
        guard let token = self.notifications.token.value else { return }
        
        self.api.updatePush(token).subscribe().disposed(by: self.disposeBag)
    }
    
    func updateRemoteSettings()
    {
        guard self.api.isAuthorized.value else { return }
        
        log("Updating remote settings:", level: .low)
        log("Locale: \(LocaleManager.shared.language.value.rawValue)", level: .low)
        log("Pushes enabled: \(self.isNotificationsAllowed)", level: .low)
        log("Timezone: \(NSTimeZone.default.secondsFromGMT() / 3600)", level: .low)
        
        self.api.updateSettings(
            LocaleManager.shared.language.value.rawValue,
            eveningPush: self.notifications.isEveningEnabled.value && self.notifications.isGranted.value,
            likePush: self.notifications.isLikeEnabled.value && self.notifications.isGranted.value,
            matchPush: self.notifications.isMatchEnabled.value && self.notifications.isGranted.value,
            messagePush: self.notifications.isMessageEnabled.value && self.notifications.isGranted.value,
            timezone: NSTimeZone.default.secondsFromGMT() / 3600
        ).subscribe().disposed(by: self.disposeBag)
    }
    
    func logout(onError: (()->())?)
    {
        guard self.actions.checkConnectionState() else { return }
        
        self.api.logout().subscribe(
        onNext: { _ in
            AnalyticsManager.shared.send(.profileDeleted)
        }, onError: { _ in
            onError?()
        }).disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        MainLMMViewController.resetStates()
        
        self.notifications.reset()
        self.actions.reset()
        self.profile.reset()
        self.lmm.reset()
        self.newFaces.reset()
        self.isFirstLaunch.accept(true)
        self.fs.reset()
        self.scenario.reset()
        self.db.reset()
        
        // TODO: separate UI layers
        ChatViewController.resetCache()
        
        AnalyticsManager.shared.reset()
    }
    
    // MARK: -
    
    fileprivate func loadSettings()
    {
        self.storage.object("is_first_launch").subscribe(onSuccess:{ [weak self] obj in
            guard let state = Bool.create(obj) else { return }
            
            self?.isFirstLaunch.accept(state)
        }).disposed(by: self.disposeBag)                
    }
    
    fileprivate func setupBindings()
    {
        self.isFirstLaunch.asObservable().subscribe(onNext: { [weak self] state in
            guard let `self` = self else { return }
            
            self.storage.store(state, key: "is_first_launch").subscribe().disposed(by: self.disposeBag)
        }).disposed(by: self.disposeBag)
        
        self.notifications.isGranted.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] state in
            log("Permissions changed - pushes access granted: \(state)", level: .low)
            self?.updateRemoteSettings()
            self?.updatePushToken()
        }).disposed(by: self.disposeBag)
    }
}
