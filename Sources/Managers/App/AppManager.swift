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
    var defaultStorage: XStorageService!
    var db: DBService!
    
    var profileManager: UserProfileManager!
    var newFacesManager: NewFacesManager!
    
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
        
        let apiConfig = ApiServiceConfigStage()
        self.apiService = ApiServiceDefault(config: apiConfig, storage: self.defaultStorage)        
    }
    
    fileprivate func setupManagers()
    {
        self.profileManager = UserProfileManager(self.db, api: self.apiService)
        self.newFacesManager = NewFacesManager(self.db, api: self.apiService)
    }
}
