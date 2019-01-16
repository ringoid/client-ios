//
//  ApiAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiAction
{
    var sourceFeed: String = ""
    var actionType: String = ""
    var targetPhotoId: String = ""
    var targetUserId: String = ""
    var actionTime: Int = 0
    
    func json() -> [String: Any]
    {
        return [
            "sourceFeed": self.sourceFeed,
            "actionType": self.actionType,
            "targetPhotoId": self.targetPhotoId,
            "targetUserId": self.targetUserId,
            "actionTime": self.actionTime
        ]
    }
}
