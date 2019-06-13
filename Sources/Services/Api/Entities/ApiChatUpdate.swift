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
    let status: ApiProfileStatus?
    let distanceText: String?
    let lastOnlineText: String?
    
    init(_ messages: [ApiMessage], pullAgainAfter: Int, status: ApiProfileStatus?, distanceText: String?, lastOnlineText: String?)
    {
        self.messages = messages
        self.pullAgainAfter = pullAgainAfter
        self.status = status
        self.distanceText = distanceText
        self.lastOnlineText = lastOnlineText
    }
}

extension ApiChatUpdate
{
    static func parse(_ dict: [String: Any]) -> ApiChatUpdate?
    {
        guard let messagesArray = dict["messages"] as? [[String: Any]]  else { return nil }
        
        let pullAgainAfter: Int = dict["pullAgainAfter"] as? Int ?? 0
        let statusStr: String = dict["lastOnlineFlag"] as? String ?? ""
        
        return ApiChatUpdate(messagesArray.compactMap({ ApiMessage.parse($0) }),
                             pullAgainAfter: pullAgainAfter,
                             status: ApiProfileStatus(rawValue: statusStr),
                             distanceText: dict["distanceText"] as? String,
                             lastOnlineText: dict["lastOnlineText"] as? String
        )
    }
}

