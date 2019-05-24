//
//  ApiProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum ApiProfileStatus: String
{
    case online = "online"
    case away = "away"
    case unknown = "unknown"
}

class ApiProfile
{
    let id: String
    let photos: [ApiPhoto]
    let status: ApiProfileStatus?
    let distanceText: String?
    let lastOnlineText: String?
    
    init(id: String, photos: [ApiPhoto], status: ApiProfileStatus?, distanceText: String?, lastOnlineText: String?)
    {
        self.id = id
        self.photos = photos
        self.status = status
        self.distanceText = distanceText
        self.lastOnlineText = lastOnlineText
    }
}

extension ApiProfile
{
    static func parse(_ dict: [String: Any]) -> ApiProfile?
    {
        guard let id = dict["userId"] as? String else { return nil }
        guard let photosArray = dict["photos"] as? [[String: Any]] else { return nil }
        
        let statusStr: String = dict["lastOnlineFlag"] as? String ?? ""

        return ApiProfile(id: id,
                          photos:  photosArray.compactMap({ ApiPhoto.parse($0) }),
                          status: ApiProfileStatus(rawValue: statusStr),
                          distanceText: dict["distanceText"] as? String,
                          lastOnlineText: dict["lastOnlineText"] as? String
        )
    }
}
