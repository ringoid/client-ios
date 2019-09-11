//
//  ApiReadMessageAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 11/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiReadMessageAction: ApiAction
{
    var userId: String = ""
    var messageId: String = ""
    
    override func json() -> [String: Any] {
        let jsonObj: [String: Any] = [
            "actionType": self.actionType,
            "actionTime": self.actionTime,
            "userId" : self.userId,
            "msgId" : self.messageId
        ]
        return jsonObj
    }
}
