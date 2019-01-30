//
//  ApiPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiPhoto
{
    let url: String
    let id: String
    let likes: Int
}

extension ApiPhoto
{
    static func parse(_ dict: [String: Any]) -> ApiPhoto?
    {
        guard let id = dict["photoId"] as? String else { return nil }
        guard let url = dict["photoUri"] as? String else { return nil }
        
        let likes: Int = (dict["likes"] as? Int) ?? 0
                
        return ApiPhoto(url: url, id: id, likes: likes)
    }
}
