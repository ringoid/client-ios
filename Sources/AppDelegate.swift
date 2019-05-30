//
//  AppDelegate.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import Firebase
import Fabric
import Crashlytics
import Sentry
import Flurry_iOS_SDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let appManager: AppManager = AppManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        FirebaseApp.configure()
        Fabric.with([Crashlytics.self])
        SentryService.shared.setup()
        Flurry.startSession(FlurryConfig.key, with: FlurrySessionBuilder())
        
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
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
    {
        return self.appManager.onOpen(url, options: options)
    }
    
    // Respond to Universal Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool
    {
        return self.appManager.onUserActivity(userActivity: userActivity, restorationHandler: restorationHandler)
    }
}

