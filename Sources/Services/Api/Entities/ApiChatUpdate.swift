//
//  ApiChatUpdate.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiChatUpdate
{
    let messages: [ApiMessage]
    let pullAgainAfter: Int
    
    init(_ messages: [ApiMessage], pullAgainAfter: Int)
    {
        self.messages = messages
        self.pullAgainAfter = pullAgainAfter
    }
}

extension ApiChatUpdate
{
    static func parse(_ dict: [String: Any]) -> ApiChatUpdate?
    {
        guard let messagesArray = dict["messages"] as? [[String: Any]]  else { return nil }
        
        let pullAgainAfter: Int = dict["pullAgainAfter"] as? Int ?? 0
        
        return ApiChatUpdate(messagesArray.compactMap({ ApiMessage.parse($0) }), pullAgainAfter: pullAgainAfter)
    }
}

