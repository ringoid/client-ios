//
//  ApiUserProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/05/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

class ApiUserProfile
{
    let photos: [ApiUserPhoto]
    let status: ApiProfileStatus?
    let statusText: String?
    let distanceText: String?
    
    init(_ photos: [ApiUserPhoto], status: ApiProfileStatus?, statusText: String?, distanceText: String?)
    {
        self.photos = photos
        self.status = status
        self.statusText = statusText
        self.distanceText = distanceText
    }
}
