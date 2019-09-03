//
//  FacebookAnalytics.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/08/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import FBSDKCoreKit

class FacebookAnalytics: AnalyticsService
{
    fileprivate var userId: String = ""
    
    // Not used in Facebook analytics
    var gender: Sex?
    {
        didSet {
            let genderStr = self.gender == .female ? "f" : "m"
            AppEvents.setUserData(genderStr, forType: .gender)
        }
    }
    var yob: Int?
    {
        didSet {
            guard let yob = self.yob else { return }
            
            let yobStr = "\(yob)0101"
            AppEvents.setUserData(yobStr, forType: .dateOfBirth)
        }
    }
    
    init()
    {
        self.userId = UserDefaults.standard.string(forKey: "analytics_facebook_key") ?? UUID().uuidString
        UserDefaults.standard.setValue(self.userId, forKey: "analytics_facebook_key")
        UserDefaults.standard.synchronize()
    }
    
    func send(_ event: AnalyticsEvent)
    {
        switch event {
        case .signedUp:
            AppEvents.logEvent(AppEvents.Name(rawValue: "SCREEN_SIGN_UP"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .profileCreated(let yob, let sex):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AUTH_USER_PROFILE_CREATED"), parameters: [
                "UUID" : self.userId,
                "yearOfBirth": yob,
                "sex": sex
                ])
            break
            
        case .profileDeleted:
            AppEvents.logEvent(AppEvents.Name(rawValue: "AUTH_USER_CALL_DELETE_HIMSELF"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .liked(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_LIKE_PHOTO"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .blocked(let reason, let sourceFeed, let fromChat):
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_BLOCK_OTHER"), parameters: [
                "UUID" : self.userId,
                "reason": reason,
                "sourceFeed": sourceFeed,
                "fromChat": fromChat ? "true" : "false"
                ])
            break
            
        case .unliked(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_UNLIKE_PHOTO"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .messaged(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_MESSAGE"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .uploadedPhoto:
            AppEvents.logEvent(AppEvents.Name(rawValue: "IMAGE_USER_UPLOAD_PHOTO"), parameters: [
                "UUID" : self.userId
                ])
            break
            
        case .deletedPhoto:
            AppEvents.logEvent(AppEvents.Name(rawValue: "IMAGE_USER_DELETE_PHOTO"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .likedFromLikes:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_LIKE_PHOTO_FROM_LIKES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .likedFromMatches:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_LIKE_PHOTO_FROM_MATCHES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .likedFromMessages:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_LIKE_PHOTO_FROM_MESSAGES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .unlikedFromLikes:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_UNLIKE_PHOTO_FROM_LIKES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .unlikedFromMatches:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_UNLIKE_PHOTO_FROM_MATCHES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .unlikedFromMessages:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_UNLIKE_PHOTO_FROM_MESSAGES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .messagedFromLikes:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_MESSAGE_FROM_LIKES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .messagedFromMatches:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_MESSAGE_FROM_MATCHES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .messagedFromMessages:
            AppEvents.logEvent(AppEvents.Name(rawValue: "ACTION_USER_MESSAGE_FROM_MESSAGES"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .openedByPush:
            AppEvents.logEvent(AppEvents.Name(rawValue: "PUSH_OPEN"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .pullToRefresh(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "PULL_TO_REFRESH"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .tapToRefresh(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "TAP_TO_REFRESH"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstSwipe(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_SWIPE"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstLikesYou(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_LIKES_YOU"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstMatch(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_MATCH"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstMessageSent(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_MESSAGE_SENT"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstMessageReceived(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_MESSAGE_RECEIVED"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .firstReplyReceived(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_REPLY_RECEIVED"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .photoAddedManually:
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_PHOTO_ADDED_MANUALLY"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .firstFieldSet:
            AppEvents.logEvent(AppEvents.Name(rawValue: "AHA_FIRST_FIELD_SET"), parameters: [
                "UUID" : self.userId,
                ])
            break
            
        case .connectionTimeout(let sourceFeed):
            AppEvents.logEvent(AppEvents.Name(rawValue: "CONNECTION_TIMEOUT"), parameters: [
                "UUID" : self.userId,
                "sourceFeed": sourceFeed
                ])
            break
            
        case .emptyFeedDiscoverNoFilters:
            AppEvents.logEvent(AppEvents.Name(rawValue: "EMPTY_FEED_DISCOVER_NO_FILTERS"), parameters: [
                "UUID" : self.userId,
                ])
            break
        }

    }
    
    func reset()
    {
        self.userId = UUID().uuidString
        UserDefaults.standard.setValue(self.userId, forKey: "analytics_facebook_key")
        UserDefaults.standard.synchronize()
    }
}
