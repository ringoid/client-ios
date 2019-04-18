//
//  AppManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class AppManager
{
    var reachability: ReachabilityService!
    var deviceService: DeviceService!
    var fileService: FileService!
    var apiService: ApiService!
    var uploader: UploaderService!
    var defaultStorage: XStorageService!
    var db: DBService!
    var notifications: NotificationService!
    var location: LocationService!
    
    var actionsManager: ActionsManager!
    var profileManager: UserProfileManager!
    var newFacesManager: NewFacesManager!
    var lmmManager: LMMManager!
    var chatManager: ChatManager!
    var settingsMananger: SettingsManager!
    var navigationManager: NavigationManager!
    var errorsManager: ErrorsManager!
    var promotionManager: PromotionManager!
    var notificationsManager: NotificationsManager!
    var syncManager: SyncManager!
    var locationManager: LocationManager!
    
    func onFinishLaunching(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        _ = AnalyticsManager.shared
        
        self.setupServices(launchOptions)
        self.setupManagers(launchOptions)        
    }
    
    func onTerminate()
    {
        self.defaultStorage.sync()
    }
    
    func onBecomeActive()
    {
        self.promotionManager.sendReferraCodeIfNeeded()
        self.settingsMananger.updateRemoteSettings()
        
        self.notifications.update()
    }
    
    func onResignActive()
    {
        self.actionsManager.commit()
    }
    
    func onOpen(_ url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        return self.promotionManager.handleOpen(url, sourceApplication:sourceApplication, annotation:annotation)
    }
    
    func onUserActivity(userActivity: NSUserActivity, restorationHandler: ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        return self.promotionManager.handleUserActivity(userActivity)
    }
    
    // Pushes: -
    
    func onGot(deviceToken: String)
    {
        self.notifications.store(deviceToken)
    }
    
    func onGot(notificationDict: [AnyHashable : Any])
    {
        self.notifications.handle(notificationDict: notificationDict)
    }
    
    
    // MARK: -
    
    fileprivate func setupServices(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        self.deviceService = DeviceServiceDefault()
        self.fileService = FileServiceDefault()
        self.defaultStorage = DefaultStorageService()
        self.db = DBService()
        self.uploader = UploaderServiceDefault(self.defaultStorage, fs: self.fileService)
        self.reachability = ReachabilityServiceDefault()
        self.notifications = NotificationsServiceDefault()
        self.location = LocationServiceDefault()
        
        #if STAGE
        let apiConfig = ApiServiceConfigStage()
        #else
        let apiConfig = ApiServiceConfigProd()        
        #endif
        
        self.apiService = ApiServiceDefault(config: apiConfig, storage: self.defaultStorage)        
    }
    
    fileprivate func setupManagers(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        self.actionsManager = ActionsManager(self.db, api: self.apiService, fs: self.fileService, storage: self.defaultStorage, reachability: self.reachability, notifications: self.notifications)
        self.newFacesManager = NewFacesManager(self.db, api: self.apiService, device: self.deviceService, actionsManager: self.actionsManager)
        self.lmmManager = LMMManager(self.db, api: self.apiService, device: self.deviceService, actionsManager: self.actionsManager, storage: self.defaultStorage)
        self.profileManager = UserProfileManager(self.db, api: self.apiService, uploader: self.uploader, fileService: self.fileService, device: self.deviceService, storage: self.defaultStorage, lmm: self.lmmManager)
        self.chatManager = ChatManager(self.db, actionsManager: self.actionsManager)
        self.settingsMananger = SettingsManager(db: self.db, api: self.apiService, fs: self.fileService, storage: self.defaultStorage, actions: self.actionsManager, lmm: self.lmmManager, newFaces: self.newFacesManager, notifications: self.notifications)
        self.navigationManager = NavigationManager()
        self.errorsManager = ErrorsManager(self.apiService, settings: self.settingsMananger)
        self.promotionManager = PromotionManager(launchOptions, api: self.apiService)
        self.notificationsManager = NotificationsManager(self.notifications, api: self.apiService)
        self.syncManager = SyncManager(self.notifications, lmm: self.lmmManager, newFaces: self.newFacesManager, profile: self.profileManager, navigation: self.navigationManager)
        self.locationManager = LocationManager(self.location, actions: self.actionsManager)
        
        ThemeManager.shared.storageService = self.defaultStorage
        LocaleManager.shared.storage = self.defaultStorage
    }
}
