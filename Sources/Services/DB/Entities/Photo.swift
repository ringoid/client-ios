//
//  Photo.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class Photo: DBServiceObject
{
    @objc dynamic var id: String!
    @objc dynamic var url: String!
    @objc dynamic var isLiked: Bool = false
}
