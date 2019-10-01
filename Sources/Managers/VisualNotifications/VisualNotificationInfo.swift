//
//  VisualNotificationInfo.swift
//  ringoid
//
//  Created by Victor Sukochev on 27/09/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import UIKit

enum VisualNotificationInfoType
{
    case message;
    case match;
}

struct VisualNotificationInfo
{
    let type: VisualNotificationInfoType
    let profileId: String
    let name: String
    let text: String
    let photoImage: UIImage?
    let photoUrl: URL?
}

extension VisualNotificationInfo: Equatable
{
    static func == (lhs: VisualNotificationInfo, rhs: VisualNotificationInfo) -> Bool
    {
        return (lhs.profileId == rhs.profileId) && (lhs.text == rhs.text) && (lhs.name == rhs.name)
    }
}
