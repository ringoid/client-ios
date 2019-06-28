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
    @objc dynamic var age: Int = 0
    let photos: List<Photo> = List<Photo>()
    
    @objc dynamic var status: Int = 0
    @objc dynamic var statusText: String!
    @objc dynamic var distanceText: String!
    
    // Info fields
    let property: RealmOptional<Int> = RealmOptional<Int>()
    let transport: RealmOptional<Int> = RealmOptional<Int>()
    let income: RealmOptional<Int> = RealmOptional<Int>()
    let height: RealmOptional<Int> = RealmOptional<Int>()
    let educationLevel: RealmOptional<Int> = RealmOptional<Int>()
    let hairColor: RealmOptional<Int> = RealmOptional<Int>()
    let children: RealmOptional<Int> = RealmOptional<Int>()
    
    @objc dynamic var name: String? = nil
    @objc dynamic var jobTitle: String? = nil
    @objc dynamic var company: String? = nil
    @objc dynamic var education: String? = nil
    @objc dynamic var about: String? = nil
    @objc dynamic var instagram: String? = nil
    @objc dynamic var tikTok: String? = nil
    @objc dynamic var whereLive: String? = nil
    @objc dynamic var whereFrom: String? = nil
    
    func orderedPhotos() -> [Photo]
    {
        guard !self.isInvalidated else { return []  }
        
        return Array(self.photos.sorted(byKeyPath: "orderPosition"))
    }
}
