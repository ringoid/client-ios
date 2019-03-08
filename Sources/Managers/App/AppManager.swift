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
    
    var actionsManager: ActionsManager!
    var profileManager: UserProfileManager!
    var newFacesManager: NewFacesManager!
    var lmmManager: LMMManager!
    var chatManager: ChatManager!
    var settingsMananger: SettingsManager!
    var navigationManager: NavigationManager!
    var errorsManager: ErrorsManager!
    
    func onFinishLaunching(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        self.setupServices()
        self.setupManagers()
    }
    
    func onTerminate()
    {
        self.defaultStorage.sync()
    }
    
    func onBecomeActive()
    {
        
    }
    
    func onResignActive()
    {
        self.actionsManager.commit()
    }
    
    // MARK: -
    
    fileprivate func setupServices()
    {
        self.deviceService = DeviceServiceDefault()
        self.fileService = FileServiceDefault()
        self.defaultStorage = DefaultStorageService()
        self.db = DBService()
        self.uploader = UploaderServiceDefault(self.defaultStorage, fs: self.fileService)
        self.reachability = ReachabilityServiceDefault()
        
        #if STAGE
        let apiConfig = ApiServiceConfigStage()
        #else
        let apiConfig = ApiServiceConfigProd()        
        #endif
        
        
        self.apiService = ApiServiceDefault(config: apiConfig, storage: self.defaultStorage)        
    }
    
    fileprivate func setupManagers()
    {
        self.actionsManager = ActionsManager(self.db, api: self.apiService, fs: self.fileService, reachability: self.reachability)
        self.profileManager = UserProfileManager(self.db, api: self.apiService, uploader: self.uploader, fileService: self.fileService, device: self.deviceService, storage: self.defaultStorage)
        self.newFacesManager = NewFacesManager(self.db, api: self.apiService, device: self.deviceService, actionsManager: self.actionsManager)
        self.lmmManager = LMMManager(self.db, api: self.apiService, device: self.deviceService, actionsManager: self.actionsManager)
        self.chatManager = ChatManager(self.db, actionsManager: self.actionsManager)
        self.settingsMananger = SettingsManager(db: self.db, api: self.apiService, fs: self.fileService, storage: self.defaultStorage, actions: self.actionsManager)
        self.navigationManager = NavigationManager()
        self.errorsManager = ErrorsManager(self.apiService, settings: self.settingsMananger)        
        
        ThemeManager.shared.storageService = self.defaultStorage
        LocaleManager.shared.storage = self.defaultStorage
    }
}
