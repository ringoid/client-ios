//
//  AnalyticsScenarioManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class AnalyticsScenarioManager
{
    let analytics: AnalyticsManager
    
    init( _ analytics: AnalyticsManager)
    {
        self.analytics = analytics
    }
    
    func checkPhotoSwipe(_ feed: SourceFeedType)
    {
        guard UserDefaults.standard.value(forKey: "scenario_first_swipe_key") == nil else { return }
        
        self.analytics.send(.firstSwipe(feed.rawValue))
        UserDefaults.standard.set(true, forKey: "scenario_first_swipe_key")
        UserDefaults.standard.synchronize()
    }
    
    func checkLikesYou(_ feed: SourceFeedType)
    {
        guard UserDefaults.standard.value(forKey: "scenario_first_likes_you_key") == nil else { return }
        
        self.analytics.send(.firstLikesYou(feed.rawValue))
        UserDefaults.standard.set(true, forKey: "scenario_first_likes_you_key")
        UserDefaults.standard.synchronize()
    }
    
    func checkFirstMatch(_ feed: SourceFeedType)
    {
        guard UserDefaults.standard.value(forKey: "scenario_first_match_key") == nil else { return }
        
        self.analytics.send(.firstMatch(feed.rawValue))
        UserDefaults.standard.set(true, forKey: "scenario_first_match_key")
        UserDefaults.standard.synchronize()
    }
    
    func checkFirstMessageSent(_ feed: SourceFeedType)
    {
        guard UserDefaults.standard.value(forKey: "scenario_first_message_sent_key") == nil else { return }
        
        self.analytics.send(.firstMessageSent(feed.rawValue))
        UserDefaults.standard.set(true, forKey: "scenario_first_message_sent_key")
        UserDefaults.standard.synchronize()
    }
    
    func checkFirstMessageReceived(_ feed: SourceFeedType)
    {
        guard UserDefaults.standard.value(forKey: "scenario_first_message_received_key") == nil else { return }
        
        self.analytics.send(.firstMessageReceived(feed.rawValue))
        UserDefaults.standard.set(true, forKey: "scenario_first_message_received_key")
        UserDefaults.standard.synchronize()
    }
    
    func checkFirstReplyReceived(_ feed: SourceFeedType)
    {
        guard UserDefaults.standard.value(forKey: "scenario_first_reply_received_key") == nil else { return }
        
        self.analytics.send(.firstReplyReceived(feed.rawValue))
        UserDefaults.standard.set(true, forKey: "scenario_first_reply_received_key")
        UserDefaults.standard.synchronize()
    }
    
    func checkPhotoAddedManually()
    {
        guard UserDefaults.standard.value(forKey: "scenario_photo_added_manually_key") == nil else { return }
        
        self.analytics.send(.photoAddedManually)
        UserDefaults.standard.set(true, forKey: "scenario_photo_added_manually_key")
        UserDefaults.standard.synchronize()
    }
    
    func reset()
    {
        UserDefaults.standard.removeObject(forKey: "was_lc_filter_shown")
        
        UserDefaults.standard.removeObject(forKey: "scenario_first_swipe_key")
        UserDefaults.standard.removeObject(forKey: "scenario_first_likes_you_key")
        UserDefaults.standard.removeObject(forKey: "scenario_first_match_key")
        UserDefaults.standard.removeObject(forKey: "scenario_first_message_sent_key")
        UserDefaults.standard.removeObject(forKey: "scenario_first_message_received_key")
        UserDefaults.standard.removeObject(forKey: "scenario_first_reply_received_key")
        UserDefaults.standard.removeObject(forKey: "scenario_photo_added_manually_key")
        UserDefaults.standard.synchronize()
    }
}
