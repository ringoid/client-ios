//
//  ApiLMMProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiLMMProfile: ApiProfile
{
    let defaultSortingOrderPosition: Int
    let notSeen: Bool
    let messages: [ApiMessage]
    
    init(id: String, defaultSortingOrderPosition: Int, notSeen: Bool, messages: [ApiMessage], photos: [ApiPhoto])
    {
        self.defaultSortingOrderPosition = defaultSortingOrderPosition
        self.notSeen = notSeen
        self.messages = messages
        
        super.init(id: id, photos: photos)
    }
}

extension ApiLMMProfile
{
    static func lmmParse(_ dict: [String: Any]) -> ApiLMMProfile?
    {
        guard let id = dict["userId"] as? String else { return nil }
        guard let defaultSortingOrderPosition = dict["defaultSortingOrderPosition"] as? Int else { return nil }
        guard let notSeen = dict["notSeen"] as? Bool else { return nil }
        guard let messagesArray = dict["messages"] as? [[String: Any]] else { return nil }
        guard let photosArray = dict["photos"] as? [[String: Any]] else { return nil }
        
        return ApiLMMProfile(id: id, defaultSortingOrderPosition: defaultSortingOrderPosition, notSeen: notSeen, messages: messagesArray.compactMap({ ApiMessage.parse($0) }), photos: photosArray.compactMap({ ApiPhoto.parse($0) }))
    }
}
