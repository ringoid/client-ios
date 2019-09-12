//
//  ApiMessage.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiMessage
{
    let id: String
    let wasYouSender: Bool
    let text: String
    let timestamp: Date
    let isRead: Bool
}

extension ApiMessage
{
    static func parse(_ dict: [String: Any]) -> ApiMessage?
    {
        guard let id = dict["clientMsgId"] as? String else { return nil }
        guard let wasYouSender = dict["wasYouSender"] as? Bool else { return nil }
        guard let text = dict["text"] as? String else { return nil }
        guard let unixTimestamp = dict["msgAt"] as? Int else { return nil }
        guard let isRead = dict["haveBeenRead"] as? Bool else { return nil }
        
        return ApiMessage(
            id: id,
            wasYouSender: wasYouSender,
            text: text,
            timestamp: Date(timeIntervalSince1970: Double(unixTimestamp) / 1000.0),
            isRead: isRead
        )
    }
}
