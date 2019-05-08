//
//  ApiViewAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiViewAction: ApiAction
{
    var viewCount: Int = 1
    var viewTime: Int = 1
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["viewCount"] = self.viewCount
        jsonObj["viewTimeMillis"] = (self.viewTime > 0) ? self.viewTime : 1
        
        return jsonObj
    }
}
