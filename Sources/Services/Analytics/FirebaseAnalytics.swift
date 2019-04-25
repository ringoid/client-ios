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
        self.userId = UserDefaults.standard.string(forKey: "analytics_firebase_key") ?? UUID().uuidString
        UserDefaults.standard.setValue(self.userId, forKey: "analytics_firebase_key")
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

        case .likedFromLikes:
            Analytics.logEvent("ACTION_USER_LIKE_PHOTO_FROM_LIKES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .likedFromMatches:
            Analytics.logEvent("ACTION_USER_LIKE_PHOTO_FROM_MATCHES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .likedFromMessages:
            Analytics.logEvent("ACTION_USER_LIKE_PHOTO_FROM_MESSAGES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .unlikedFromLikes:
            Analytics.logEvent("ACTION_USER_UNLIKE_PHOTO_FROM_LIKES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .unlikedFromMatches:
            Analytics.logEvent("ACTION_USER_UNLIKE_PHOTO_FROM_MATCHES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .unlikedFromMessages:
            Analytics.logEvent("ACTION_USER_UNLIKE_PHOTO_FROM_MESSAGES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .messagedFromLikes:
            Analytics.logEvent("ACTION_USER_MESSAGE_FROM_LIKES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .messagedFromMatches:
            Analytics.logEvent("ACTION_USER_MESSAGE_FROM_MATCHES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .messagedFromMessages:
            Analytics.logEvent("ACTION_USER_MESSAGE_FROM_MESSAGES", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .openedByPush:
            Analytics.logEvent("PUSH_OPEN", parameters: [
                "UUID": self.userId
                ])
            break
            
        case .pullToRefresh(let sourceFeed):
            Analytics.logEvent("PULL_TO_REFRESH", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstSwipe(let sourceFeed):
            Analytics.logEvent("AHA_FIRST_SWIPE", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstLikesYou(let sourceFeed):
            Analytics.logEvent("AHA_FIRST_LIKES_YOU", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstMatch(let sourceFeed):
            Analytics.logEvent("AHA_FIRST_MATCH", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstMessageSent(let sourceFeed):
            Analytics.logEvent("AHA_FIRST_MESSAGE_SENT", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstMessageReceived(let sourceFeed):
            Analytics.logEvent("AHA_FIRST_MESSAGE_RECEIVED", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstReplyReceived(let sourceFeed):
            Analytics.logEvent("AHA_FIRST_REPLY_RECEIVED", parameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .photoAddedManually:
            Analytics.logEvent("AHA_PHOTO_ADDED_MANUALLY", parameters: [
                "UUID": self.userId,
                ])
            break
        }
    }
    
    func reset()
    {
        self.userId = UUID().uuidString
        UserDefaults.standard.setValue(self.userId, forKey: "analytics_firebase_key")
        UserDefaults.standard.synchronize()
    }
}
