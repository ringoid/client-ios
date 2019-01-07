//
//  ApiProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiProfile
{
    let id: String
    let photos: [ApiPhoto]
}

extension ApiProfile
{
    static func parse(_ dict: [String: Any]) -> ApiProfile?
    {
        guard let id = dict["userId"] as? String else { return nil }
        guard let photosArray = dict["photos"] as? [[String: Any]] else { return nil }
        
        return ApiProfile(id: id, photos: photosArray.compactMap({ ApiPhoto.parse($0) }))
    }
}
