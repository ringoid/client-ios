//
//  ApiMessageAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 16/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiMessageAction: ApiAction
{
    var id: String = ""
    var text: String = ""
    
    override func json() -> [String: Any] {
        var jsonObj = super.json()
        jsonObj["clientMsgId"] = self.id
        jsonObj["text"] = self.text
        
        return jsonObj
    }
}
