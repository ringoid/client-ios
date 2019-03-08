//
//  ApiOpenChat.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiOpenChatAction: ApiAction
{
    var openChatCount: Int = 0
    var openChatTime: Int = 0
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["openChatCount"] = self.openChatCount
        jsonObj["openChatTimeMillis"] = self.openChatTime
        
        return jsonObj
    }
}
