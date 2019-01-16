//
//  ApiLikeAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiLikeAction: ApiAction
{
    var likeCount: Int = 0
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["likeCount"] = self.likeCount
        
        return jsonObj
    }
}
