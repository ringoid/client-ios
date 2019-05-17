//
//  DeviceServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 30/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit
import DeviceKit

class DeviceServiceDefault: DeviceService
{
    fileprivate let resolutions: [Int: String] = [
        480: "480x640",
        640: "640x852",
        720: "720x960",
        750: "750x1000",
        828: "828x1104",
        1080: "1080x1440",
        1125: "1125x1500",
        1242: "1242x1656",
        1440: "1440x1920"
    ]
    
    var photoResolution: String
    {
        let displayWidth: Int = Int(UIScreen.main.bounds.width * UIScreen.main.nativeScale)
        
        for resolutionWidth in self.resolutions.keys.sorted(by:{ $0 > $1 })
        {
            if displayWidth >= resolutionWidth {
                return self.resolutions[resolutionWidth]!
            }
        }
        
        return self.resolutions.values.first!
    }
    
    var deviceName: String
    {
        return Device().description
    }
    
    var appVersion: String
    {
        return (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as?  String) ?? "0"
    }
}
