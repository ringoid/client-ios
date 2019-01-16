//
//  ApiBlockAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiBlockAction: ApiAction
{
    var blockReasonNum: Int = 0
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["blockReasonNum"] = self.blockReasonNum
        
        return jsonObj
    }
}
