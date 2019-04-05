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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let appManager: AppManager = AppManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        FirebaseApp.configure()
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
    
    //MARK: - Pushes management
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.appManager.onGot(deviceToken: token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error)
    {
        log("failed to get DeviceToken: \(error)", level: .high)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        self.appManager.onGot(notificationDict: userInfo)
        
//        if UIApplication.shared.applicationState != .background {
//            completionHandler(.noData)
//            return
//        }
    }
}

