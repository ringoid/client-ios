//
//  AnalyticsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 05/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class AnalyticsManager
{
    static let shared = AnalyticsManager()
    
    fileprivate let services: [AnalyticsService] = [
        FirebaseAnalytics()
    ]
    
    private init() {}
    
    func send(_ event: AnalyticsEvent)
    {
        self.services.forEach({  $0.send(event) })
    }
}
