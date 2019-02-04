//
//  ApiUserPhotoPlaceholder.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiUserPhotoPlaceholder {
    let url: String
    let originId: String
    let clientId: String
}

extension ApiUserPhotoPlaceholder
{
    static func parse(_ dict: [String: Any]?) -> ApiUserPhotoPlaceholder?
    {
        guard let url = dict?["uri"] as? String else { return nil }
        guard let originId = dict?["originPhotoId"] as? String else { return nil }
        guard let clientId = dict?["clientPhotoId"] as? String else { return nil }
        
        return ApiUserPhotoPlaceholder(
            url: url,
            originId: originId,
            clientId: clientId
        )
    }
}
