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
    case offline = "offline"
    case unknown = "unknown"
}

class ApiProfile
{
    let id: String
    let age: Int
    let photos: [ApiPhoto]
    let status: ApiProfileStatus?
    let distanceText: String?
    let lastOnlineText: String?
    let sex: String?
    let info: ApiUserProfileInfo
    
    init(id: String, age: Int, photos: [ApiPhoto], status: ApiProfileStatus?, distanceText: String?, lastOnlineText: String?, sex: String?, info: ApiUserProfileInfo)
    {
        self.id = id
        self.age = age
        self.photos = photos
        self.status = status
        self.distanceText = distanceText
        self.lastOnlineText = lastOnlineText
        self.sex = sex
        self.info = info
    }
}

extension ApiProfile
{
    static func parse(_ dict: [String: Any]) -> ApiProfile?
    {
        guard let id = dict["userId"] as? String else { return nil }
        guard let age = dict["age"] as? Int else { return nil }
        guard let sex = dict["sex"] as? String else { return nil }
        guard let photosArray = dict["photos"] as? [[String: Any]] else { return nil }
        guard let info = ApiUserProfileInfo.parse(dict) else { return nil }
        
        let statusStr: String = dict["lastOnlineFlag"] as? String ?? ""

        return ApiProfile(id: id,
                          age: age,
                          photos:  photosArray.compactMap({ ApiPhoto.parse($0) }),
                          status: ApiProfileStatus(rawValue: statusStr),
                          distanceText: dict["distanceText"] as? String,
                          lastOnlineText: dict["lastOnlineText"] as? String,
                          sex: sex,
                          info: info
        )
    }
}
