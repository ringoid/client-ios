//
//  DeviceServiceDefault.swift
//  ringoid
//
//  Created by Victor Sukochev on 30/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

class DeviceServiceDefault: DeviceService
{
    fileprivate let resolutions: [Int: String] = [
        480: "480x640",
        720: "720x960",
        750: "750x1000",
        828: "828x1344",
        1080: "1080x1440",
        1125: "1125x1827",
        1242: "1242x2016",
        1440: "1440x1920"
    ]
    
    var photoResolution: String
    {
        var diff = Int.max
        var closeResolution: String = self.resolutions.values.first!
        let displayWidth: Int = Int(UIScreen.main.bounds.width * UIScreen.main.nativeScale)
        
        for (_, resolution) in self.resolutions.enumerated()
        {
            let currentDiff = abs(resolution.key - displayWidth)
            if currentDiff < diff {
                diff = currentDiff
                closeResolution = resolution.value
            }
        }
        
        return closeResolution
    }
}
