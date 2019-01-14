//
//  Message.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class Message: Object
{
    @objc dynamic var wasYouSender: Bool = false
    @objc dynamic var text: String!
}
