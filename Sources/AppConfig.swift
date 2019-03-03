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
    
    static let termsUrl: URL = URL(string: "http://ringoid.com/terms.html")!
    static let policyUrl: URL = URL(string: "http://ringoid.com/privacy.html")!
    static let licensesUrl: URL = URL(string: "http://ringoid.com/licenses-ios.html")!
    static let appstoreUrl: URL = URL(string: "https://itunes.apple.com/il/app/speakapp-voice-messenger/id1453136158?mt=8")!
}
