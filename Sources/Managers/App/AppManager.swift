//
//  AppManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import FBSDKCoreKit

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
    var scenarioManager: AnalyticsScenarioManager!
    var transitionManager: TransitionManager!
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    func onFinishLaunching(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        _ = AnalyticsManager.shared
        
        let application = UIApplication.shared
        FBSDKApplicationDelegate.sharedInstance()?.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        self.setupServices(launchOptions)
        self.setupManagers(launchOptions)
        self.setupBindings()
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
        FBSDKAppEvents.activateApp()
    }
    
    func onResignActive()
    {
        self.actionsManager.commit()
    }
    
    func onOpen(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
    {
        let application = UIApplication.shared
        if FBSDKApplicationDelegate.sharedInstance()!.application(application, open: url, options: options) {
            return true
        }
        
        guard let sourceApp = options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            let annotation = options[UIApplication.OpenURLOptionsKey.annotation] else { return false }
        
        if FBSDKApplicationDelegate.sharedInstance()!.application(application, open: url, sourceApplication: sourceApp, annotation: annotation) {
            return true
        }
        
        return self.promotionManager.handleOpen(url, sourceApplication:sourceApp, annotation:annotation)
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
        self.scenarioManager = AnalyticsScenarioManager(AnalyticsManager.shared)
        self.chatManager = ChatManager(self.db, actionsManager: self.actionsManager, scenario: self.scenarioManager)
        self.settingsMananger = SettingsManager(db: self.db, api: self.apiService, fs: self.fileService, storage: self.defaultStorage, actions: self.actionsManager, lmm: self.lmmManager, newFaces: self.newFacesManager, notifications: self.notifications, scenario: self.scenarioManager)
        self.navigationManager = NavigationManager()
        self.errorsManager = ErrorsManager(self.apiService, settings: self.settingsMananger)
        self.promotionManager = PromotionManager(launchOptions, api: self.apiService)
        self.notificationsManager = NotificationsManager(self.notifications, api: self.apiService)
        self.syncManager = SyncManager(self.notifications, lmm: self.lmmManager, newFaces: self.newFacesManager, profile: self.profileManager, navigation: self.navigationManager)
        self.locationManager = LocationManager(self.location, actions: self.actionsManager)
        self.transitionManager = TransitionManager(self.db, lmm: self.lmmManager)
        
        ThemeManager.shared.storageService = self.defaultStorage
        LocaleManager.shared.storage = self.defaultStorage
    }
    
    fileprivate func setupBindings()
    {
        self.apiService.customerId.asObservable().subscribe(onNext: { customerId in
            SentryService.shared.customerId = customerId
        }).disposed(by: self.disposeBag)
    }
}
