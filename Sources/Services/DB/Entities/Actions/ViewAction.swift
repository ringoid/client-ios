//
//  ViewAction.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class ViewAction: Action
{
    @objc dynamic var viewCount: Int = 0
    @objc dynamic var viewTimeSec: Int = 0
}
