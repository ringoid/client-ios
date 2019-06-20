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
    let status: ApiProfileStatus?
    let distanceText: String?
    let lastOnlineText: String?
    
    init(_ messages: [ApiMessage], status: ApiProfileStatus?, distanceText: String?, lastOnlineText: String?)
    {
        self.messages = messages
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
        
        let statusStr: String = dict["lastOnlineFlag"] as? String ?? ""
        
        return ApiChatUpdate(messagesArray.compactMap({ ApiMessage.parse($0) }),                             
                             status: ApiProfileStatus(rawValue: statusStr),
                             distanceText: dict["distanceText"] as? String,
                             lastOnlineText: dict["lastOnlineText"] as? String
        )
    }
}

