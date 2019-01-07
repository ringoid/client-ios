//
//  ApiPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

enum PhotoResolution: String
{
    case small = "480x640"
    case normal = "720x960"
    case hd = "1080x1440"
    case ultraHD = "1440x1920"
}

struct ApiPhoto
{
    let url: String
    let id: String
}

extension ApiPhoto
{
    static func parse(_ dict: [String: Any]) -> ApiPhoto?
    {
        guard let id = dict["photoId"] as? String else { return nil }
        guard let url = dict["photoUri"] as? String else { return nil }
        
        return ApiPhoto(url: url, id: id)
    }
}
