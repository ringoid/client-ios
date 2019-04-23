//
//  FlurryAnalytics.swift
//  ringoid
//
//  Created by Victor Sukochev on 23/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Flurry_iOS_SDK

class FlurryAnalytics: AnalyticsService
{
    fileprivate var userId: String = ""
    
    init()
    {
        self.userId = UserDefaults.standard.string(forKey: "analytics_key") ?? UUID().uuidString
        UserDefaults.standard.setValue(self.userId, forKey: "analytics_key")
        UserDefaults.standard.synchronize()
        
       Flurry.setUserID(self.userId)
    }
    
    func send(_ event: AnalyticsEvent)
    {
        switch event {
        case .signedUp:
            Flurry.logEvent("SCREEN_SIGN_UP", withParameters:  [
                "UUID": self.userId
                ])
            break
            
        case .profileCreated(let yob, let sex):
            Flurry.logEvent("AUTH_USER_PROFILE_CREATED", withParameters: [
                "UUID": self.userId,
                "yearOfBirth": yob,
                "sex": sex
                ])
            break
            
        case .profileDeleted:
            Flurry.logEvent("AUTH_USER_CALL_DELETE_HIMSELF", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .liked(let sourceFeed):
            Flurry.logEvent("ACTION_USER_LIKE_PHOTO", withParameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .blocked(let reason, let sourceFeed, let fromChat):
            Flurry.logEvent("ACTION_USER_BLOCK_OTHER", withParameters: [
                "UUID": self.userId,
                "reason": reason,
                "sourceFeed": sourceFeed,
                "fromChat": fromChat ? "true" : "false"
                ])
            break
            
        case .unliked(let sourceFeed):
            Flurry.logEvent("ACTION_USER_UNLIKE_PHOTO", withParameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .messaged(let sourceFeed):
            Flurry.logEvent("ACTION_USER_MESSAGE", withParameters: [
                "UUID": self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .uploadedPhoto:
            Flurry.logEvent("IMAGE_USER_UPLOAD_PHOTO", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .deletedPhoto:
            Flurry.logEvent("IMAGE_USER_DELETE_PHOTO", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .likedFromLikes:
            Flurry.logEvent("ACTION_USER_LIKE_PHOTO_FROM_LIKES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .likedFromMatches:
            Flurry.logEvent("ACTION_USER_LIKE_PHOTO_FROM_MATCHES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .likedFromMessages:
            Flurry.logEvent("ACTION_USER_LIKE_PHOTO_FROM_MESSAGES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .unlikedFromLikes:
            Flurry.logEvent("ACTION_USER_UNLIKE_PHOTO_FROM_LIKES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .unlikedFromMatches:
            Flurry.logEvent("ACTION_USER_UNLIKE_PHOTO_FROM_MATCHES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .unlikedFromMessages:
            Flurry.logEvent("ACTION_USER_UNLIKE_PHOTO_FROM_MESSAGES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .messagedFromLikes:
            Flurry.logEvent("ACTION_USER_MESSAGE_FROM_LIKES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .messagedFromMatches:
            Flurry.logEvent("ACTION_USER_MESSAGE_FROM_MATCHES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .messagedFromMessages:
            Flurry.logEvent("ACTION_USER_MESSAGE_FROM_MESSAGES", withParameters: [
                "UUID": self.userId
                ])
            break
            
        case .openedByPush:
            Flurry.logEvent("PUSH_OPEN", withParameters: [
                "UUID": self.userId
                ])
            break
        }
    }
}
