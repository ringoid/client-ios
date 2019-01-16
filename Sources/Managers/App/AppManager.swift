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
    var apiService: ApiService!
    var uploader: UploaderService!
    var defaultStorage: XStorageService!
    var db: DBService!
    
    var actionsManager: ActionsManager!
    var profileManager: UserProfileManager!
    var newFacesManager: NewFacesManager!
    var lmmManager: LMMManager!
    
    func onFinishLaunching(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        self.setupServices()
        self.setupManagers()
    }
    
    // MARK: -
    
    fileprivate func setupServices()
    {
        self.defaultStorage = DefaultStorageService()
        self.db = DBService()
        self.uploader = UploaderServiceDefault()
        
        let apiConfig = ApiServiceConfigStage()
        self.apiService = ApiServiceDefault(config: apiConfig, storage: self.defaultStorage)        
    }
    
    fileprivate func setupManagers()
    {
        self.actionsManager = ActionsManager(self.db, api: self.apiService)
        self.profileManager = UserProfileManager(self.db, api: self.apiService, uploader: self.uploader)
        self.newFacesManager = NewFacesManager(self.db, api: self.apiService, actionsManager: self.actionsManager)
        self.lmmManager = LMMManager(self.db, api: self.apiService, actionsManager: self.actionsManager)
        
        ThemeManager.shared.storageService = self.defaultStorage
    }
}
