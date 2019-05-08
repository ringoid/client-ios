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
    var viewChatCount: Int = 1
    var viewChatTime: Int = 1
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["viewChatCount"] = self.viewChatCount
        jsonObj["viewChatTimeMillis"] = (self.viewChatTime > 0) ? self.viewChatTime : 1
        
        return jsonObj
    }
}
