//
//  ApiUserPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/02/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiUserPhoto
{
    let id: String
    let url: String
    let originPhotoId: String
    let likes: Int
    let isBlocked: Bool
}

extension ApiUserPhoto
{
    static func parse(_ dict: [String: Any]?) -> ApiUserPhoto?
    {
        guard let url = dict?["photoUri"] as? String else { return nil }
        guard let id = dict?["photoId"] as? String else { return nil }
        guard let originPhotoId = dict?["originPhotoId"] as? String else { return nil }
        guard let likes = dict?["likes"] as? Int else { return nil }
        guard let isBlocked = dict?["blocked"] as? Bool else { return nil }

        return ApiUserPhoto(
            id: id,
            url: url,
            originPhotoId: originPhotoId,
            likes: likes,
            isBlocked: isBlocked
        )
    }
}
