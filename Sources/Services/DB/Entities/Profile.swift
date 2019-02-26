//
//  Profile.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class Profile: DBServiceObject
{
    @objc dynamic var id: String!
    let photos: List<Photo> = List<Photo>()
    
    func orderedPhotos() -> [Photo]
    {
        return Array(self.photos.sorted(byKeyPath: "orderPosition"))
    }
}
