//
//  ApiProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 02/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ApiProfile
{
    let accessToken: String
    let customerId: String
}

extension ApiProfile
{
    static func parse(_ dict: [String: Any]) -> ApiProfile?
    {
        guard let accessToken = dict["accessToken"] as? String else { return nil }
        guard let customerId = dict["customerId"] as? String else { return nil }
                
        return ApiProfile(accessToken: accessToken, customerId: customerId)
    }
}
