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
        SentryService.shared.setup()
        
        self.appManager.onFinishLaunching(launchOptions)
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication)
    {
        self.appManager.onTerminate()
    }
    
    func applicationWillResignActive(_ application: UIApplication)
    {
        self.appManager.onResignActive()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        self.appManager.onBecomeActive()
    }
    
    // Respond to URI scheme links
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool
    {
        return self.appManager.onOpen(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        return self.appManager.onUserActivity(userActivity: userActivity, restorationHandler: restorationHandler)
    }
}

