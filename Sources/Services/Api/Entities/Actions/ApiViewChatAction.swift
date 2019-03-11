//
//  ApiViewChatAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiViewChatAction: ApiAction
{
    var viewChatCount: Int = 0
    var viewChatTime: Int = 0
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["viewChatCount"] = self.viewChatCount
        jsonObj["viewChatTimeMillis"] = self.viewChatTime
        
        return jsonObj
    }
}