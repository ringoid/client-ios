//
//  VisualNotificationInfo.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

struct VisualNotificationInfo
{
    let profileId: String
    let text: String
    let photoImage: UIImage?
    let photoUrl: URL?
}

extension VisualNotificationInfo: Equatable
{
    static func == (lhs: VisualNotificationInfo, rhs: VisualNotificationInfo) -> Bool
    {
        return (lhs.profileId == rhs.profileId) && (lhs.text == rhs.text)
    }
}