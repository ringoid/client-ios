//
//  Profile.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

enum OnlineStatus: Int
{
    case unknown = 0
    case offline = 1
    case away = 2
    case online = 3
}

class Profile: DBServiceObject
{
    @objc dynamic var id: String!
    let photos: List<Photo> = List<Photo>()
    
    @objc dynamic var status: Int = 0
    @objc dynamic var statusText: String!
    @objc dynamic var distanceText: String!
    
    func orderedPhotos() -> [Photo]
    {
        guard !self.isInvalidated else { return []  }
        
        return Array(self.photos.sorted(byKeyPath: "orderPosition"))
    }
}
