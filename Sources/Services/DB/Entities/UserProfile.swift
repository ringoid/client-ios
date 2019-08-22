//
//  UserProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 21/06/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class UserProfile: DBServiceObject
{
    // Info fields
    let property: RealmOptional<Int> = RealmOptional<Int>()
    let transport: RealmOptional<Int> = RealmOptional<Int>()
    let income: RealmOptional<Int> = RealmOptional<Int>()
    let height: RealmOptional<Int> = RealmOptional<Int>()
    let educationLevel: RealmOptional<Int> = RealmOptional<Int>()
    let hairColor: RealmOptional<Int> = RealmOptional<Int>()
    let children: RealmOptional<Int> = RealmOptional<Int>()
    
    @objc dynamic var statusInfo: String? = nil
    @objc dynamic var name: String? = nil
    @objc dynamic var jobTitle: String? = nil
    @objc dynamic var company: String? = nil
    @objc dynamic var education: String? = nil
    @objc dynamic var about: String? = nil
    @objc dynamic var instagram: String? = nil
    @objc dynamic var tikTok: String? = nil
    @objc dynamic var whereLive: String? = nil
    @objc dynamic var whereFrom: String? = nil
}
