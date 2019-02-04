//
//  UserPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class UserPhoto: DBServiceObject
{
    @objc dynamic var id: String!
    @objc dynamic var originPhotoId: String!
    @objc dynamic var clientPhotoId: String!
    @objc dynamic var path: String!
    @objc dynamic var pathType: Int = 0
    @objc dynamic var likes: Int = 0
    @objc dynamic var isBlocked: Bool = false
}

extension UserPhoto
{
    func filepath() -> FilePath
    {
        let type = FileType(rawValue: self.pathType)!
        
        return FilePath(filename: self.path, type: type)
    }
    
    func setFilepath(_ filepath: FilePath)
    {
        self.path = filepath.filename
        self.pathType = filepath.type.rawValue
    }
}
