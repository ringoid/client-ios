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
            UserDefaults.standard.set(newValue, forKey: "notificationsAllowedByUser")
            UserDefaults.standard.synchronize()
        }
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(db: DBService, api: ApiService, fs: FileService, storage: XStorageService, actions: ActionsManager, lmm: LMMManager, newFaces: NewFacesManager, notifications: NotificationService)
    {
        self.db = db
        self.api = api
        self.fs = fs
        self.storage = storage
        self.actions = actions
        self.lmm = lmm
        self.newFaces = newFaces
        self.notifications = notifications
        
        self.loadSettings()
        self.updateRemoteSettings()
        self.setupBindings()
    }
    
    func updateRemoteSettings()
    {
        guard self.api.isAuthorized.value else { return }
        
        self.api.updateSettings(
            LocaleManager.shared.language.value.rawValue,
            push: self.isNotificationsAllowed,
            timezone: NSTimeZone.default.secondsFromGMT() / 3600
            ).subscribe().disposed(by: self.disposeBag)
    }
    
    func logout()
    {
        guard self.actions.checkConnectionState() else { return }
        
        self.api.logout().subscribe().disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.actions.reset()
        self.lmm.reset()
        self.newFaces.reset()
        self.isFirstLaunch.accept(true)
        self.db.reset()
        self.fs.reset()
    }
    
    // MARK: -
    
    fileprivate func loadSettings()
    {
        self.storage.object("is_first_launch").subscribe(onNext:{ [weak self] obj in
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
        
        self.notifications.isGranted.asObservable().subscribe(onNext: { [weak self] _ in
            self?.updateRemoteSettings()
        }).disposed(by: self.disposeBag)
    }
}
