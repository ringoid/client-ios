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
    let wasYouSender: Bool
    let text: String
}

extension ApiMessage
{
    static func parse(_ dict: [String: Any]) -> ApiMessage?
    {
        guard let wasYouSender = dict["wasYouSender"] as? Bool else { return nil }
        guard let text = dict["text"] as? String else { return nil }
        
        return ApiMessage(wasYouSender: wasYouSender, text: text)
    }
}
