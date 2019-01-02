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
    let apiService: ApiService
    
    init(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    {        
        let apiConfig = ApiServiceConfigStage()
        self.apiService = ApiServiceDefault(config: apiConfig)
    }
}
