//
//  FirebaseAnalytics.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Firebase

class FirebaseAnalytics: AnalyticsService
{
    fileprivate var userId: String = ""
    
    init()
    {
        self.userId = UserDefaults.standard.string(forKey: "analytics_key") ?? UUID().uuidString
        UserDefaults.standard.setValue(self.userId, forKey: "analytics_key")
        UserDefaults.standard.synchronize()
        
        AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(true)
        Analytics.setUserID(self.userId)
    }
    
    func send(_ event: AnalyticsEvent)
    {
        switch event {
        case .signedUp:
            Analytics.logEvent("SCREEN_SIGN_UP", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .profileCreated(let yob, let sex):
            Analytics.logEvent("AUTH_USER_PROFILE_CREATED", parameters: [
                "UUID": self.userId,
                "yearOfBirth": yob,
                "sex": sex
                ])
            break
            
        case .profileDeleted:
            Analytics.logEvent("AUTH_USER_CALL_DELETE_HIMSELF", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .liked(let sourceFeed):
            Analytics.logEvent("ACTION_USER_LIKE_PHOTO", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .blocked(let reason, let sourceFeed, let fromChat):
            Analytics.logEvent("ACTION_USER_BLOCK_OTHER", parameters: [
                "UUID": self.userId,
                "reason": reason,
                "sourceFeed": sourceFeed,
                "fromChat": fromChat ? "true" : "false"
                ])
            break
            
        case .unliked(let sourceFeed):
            Analytics.logEvent("ACTION_USER_UNLIKE_PHOTO", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .messaged(let sourceFeed):
            Analytics.logEvent("ACTION_USER_MESSAGE", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .uploadedPhoto:
            Analytics.logEvent("IMAGE_USER_UPLOAD_PHOTO", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .deletedPhoto:
            Analytics.logEvent("IMAGE_USER_DELETE_PHOTO", parameters: [
                "UUID": self.userId
                ])
            break
        }
        
        
    }
}
