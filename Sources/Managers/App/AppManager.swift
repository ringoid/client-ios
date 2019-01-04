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
    
    var profileManager: ProfileManager!
    
    func onFinishLaunching(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {
        self.setupServices()
        self.setupManagers()
    }
    
    // MARK: -
    
    fileprivate func setupServices()
    {
        self.defaultStorage = DefaultStorageService()
        
        let apiConfig = ApiServiceConfigStage()
        self.apiService = ApiServiceDefault(config: apiConfig, storage: self.defaultStorage)        
    }
    
    fileprivate func setupManagers()
    {
        self.profileManager = ProfileManager()
    }
}
