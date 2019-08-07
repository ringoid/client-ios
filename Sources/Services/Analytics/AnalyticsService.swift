//
//  AnalyticsService.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum AnalyticsEvent
{
    case signedUp;
    
    case profileCreated(Int, String);
    case profileDeleted;
    case liked(String);
    case blocked(Int, String, Bool);
    case unliked(String);
    case messaged(String);
    case uploadedPhoto;
    case deletedPhoto;
    case likedFromLikes;
    case likedFromMatches;
    case likedFromMessages;
    case unlikedFromLikes;
    case unlikedFromMatches;
    case unlikedFromMessages;
    case messagedFromLikes;
    case messagedFromMatches;
    case messagedFromMessages;
    case openedByPush;
    case pullToRefresh(String);
    case tapToRefresh(String);
    
    case firstSwipe(String);
    case firstLikesYou(String);
    case firstMatch(String);
    case firstMessageSent(String);
    case firstMessageReceived(String);
    case firstReplyReceived(String);
    case photoAddedManually;
    case firstFieldSet;
    
}

protocol AnalyticsService: class
{
    var gender: Sex? { get set }
    var yob: Int? { get set }
    
    func send(_ event: AnalyticsEvent)
    func reset()
}
