//
//  AppConfig.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import CoreGraphics
import Foundation

class AppConfig
{
    static let photoRatio: CGFloat = 4.0 / 3.0
    
    // MARK: - URLs
    
    static let termsUrl: URL = URL(string: "https://ringoid.com/terms.html")!
    static let policyUrl: URL = URL(string: "https://ringoid.com/privacy.html")!
    static let licensesUrl: URL = URL(string: "https://ringoid.com/licenses-ios.html")!
    static let appstoreUrl: URL = URL(string: "https://itunes.apple.com/us/app/ringoid-see-likes/id1453136158?ls=1&mt=8")!
    
    #if STAGE
    static let fcmSenderId: String = "691533652276"
    #else
    static let fcmSenderId: String = "1080519350118"
    #endif
}
