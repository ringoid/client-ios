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
    
    var gender: Sex?
    {
        didSet {
            self.services.forEach({ $0.gender = self.gender })
        }
    }
    
    var yob: Int?
    {
        didSet {
            self.services.forEach({  $0.yob = self.yob })
        }
    }
    
    fileprivate let services: [AnalyticsService] = [
        FirebaseAnalytics(),
        FlurryAnalytics()
    ]
    
    private init() {}
    
    func send(_ event: AnalyticsEvent)
    {
        self.services.forEach({  $0.send(event) })
    }
    
    func reset()
    {
        self.services.forEach({ $0.reset() })
    }
}
