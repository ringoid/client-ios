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
    var viewCount: Int = 0
    var viewTime: Int = 0
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["viewCount"] = self.viewCount
        jsonObj["viewTime"] = self.viewTime
        
        return jsonObj
    }
}
