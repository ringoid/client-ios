//
//  ApiLocationAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/04/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiLocationAction: ApiAction
{
    var lat: Double = 0.0
    var lon: Double = 0.0
    
    override func json() -> [String: Any] {
        let jsonObj: [String: Any] = [
            "actionType": self.actionType,
            "actionTime": self.actionTime,
            "lat" : self.lat,
            "lon" : self.lon
        ]
        return jsonObj
    }
}
