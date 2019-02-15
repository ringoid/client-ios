//
//  AppDelegate.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Sentry

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let appManager: AppManager = AppManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        Fabric.with([Crashlytics.self])
        
        self.appManager.onFinishLaunching(launchOptions)
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        self.appManager.onTerminate()
    }
    
    // MARK: -
    
    fileprivate func setupSenty()
    {
        do {
            Client.shared = try Client(dsn: "https://179c556658a3465d852019ffbb5aaac1@sentry.io/1387002")
            try Client.shared?.startCrashHandler()
        } catch let error {
            print("Sentry error: \(error)")
        }
    }
}

