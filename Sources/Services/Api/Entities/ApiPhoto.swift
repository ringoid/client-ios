//
//  ApiPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiPhoto {
    let url: String
    let originId: String
    let clientId: String
}

extension ApiPhoto
{
    static func parse(_ dict: [String: Any]?) -> ApiPhoto?
    {
        guard let url = dict?["uri"] as? String else { return nil }
        guard let originId = dict?["originPhotoId"] as? String else { return nil }
        guard let clientId = dict?["clientPhotoId"] as? String else { return nil }
        
        return ApiPhoto(
            url: url,
            originId: originId,
            clientId: clientId
        )
    }
}
