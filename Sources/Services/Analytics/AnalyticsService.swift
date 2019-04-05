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
}

protocol AnalyticsService
{
    func send(_ event: AnalyticsEvent)
}
