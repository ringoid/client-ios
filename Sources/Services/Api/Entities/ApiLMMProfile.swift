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
    
    init(id: String, age: Int, defaultSortingOrderPosition: Int, notSeen: Bool, messages: [ApiMessage], photos: [ApiPhoto], status: ApiProfileStatus?, distanceText: String?, lastOnlineText: String?, sex: String?, info: ApiUserProfileInfo, totalLikes: Int)
    {
        self.defaultSortingOrderPosition = defaultSortingOrderPosition
        self.notSeen = notSeen
        self.messages = messages

        super.init(id: id, age: age, photos: photos, status: status, distanceText: distanceText, lastOnlineText: lastOnlineText, sex: sex, info:  info, totalLikes: totalLikes)
    }
}

extension ApiLMMProfile
{
    static func lmmParse(_ dict: [String: Any]) -> ApiLMMProfile?
    {
        guard let id = dict["userId"] as? String else { return nil }
        guard let age = dict["age"] as? Int else { return nil }
        guard let defaultSortingOrderPosition = dict["defaultSortingOrderPosition"] as? Int else { return nil }
        guard let notSeen = dict["notSeen"] as? Bool else { return nil }
        guard let messagesArray = dict["messages"] as? [[String: Any]] else { return nil }
        guard let photosArray = dict["photos"] as? [[String: Any]] else { return nil }
        guard let totalLikes = dict["totalLikes"] as? Int else { return nil }
        guard let info = ApiUserProfileInfo.parse(dict) else { return nil }
        
        let statusStr: String = dict["lastOnlineFlag"] as? String ?? ""
        
        return ApiLMMProfile(id: id,
                             age: age,
                             defaultSortingOrderPosition: defaultSortingOrderPosition,
                             notSeen: notSeen, messages: messagesArray.compactMap({ ApiMessage.parse($0) }),
                             photos: photosArray.compactMap({ ApiPhoto.parse($0) }),
                             status: ApiProfileStatus(rawValue: statusStr),
                             distanceText: dict["distanceText"] as? String,
                             lastOnlineText: dict["lastOnlineText"] as? String,
                             sex: dict["sex"] as? String,
                             info: info,
                             totalLikes: totalLikes
        )
    }
}
