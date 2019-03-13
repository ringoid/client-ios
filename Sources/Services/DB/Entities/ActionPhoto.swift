//
//  ActionPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class ActionPhoto: DBServiceObject
{
    @objc dynamic var id: String!
    @objc dynamic var path: String!
    @objc dynamic var pathType: Int = 0
    @objc dynamic var isLiked: Bool = false
}

extension Photo
{
    func actionInstance() -> ActionPhoto
    {
        let actionPhoto = ActionPhoto()
        
        actionPhoto.id = self.id
        actionPhoto.path = self.path
        actionPhoto.pathType = self.pathType
        actionPhoto.isLiked = self.isLiked
        actionPhoto.orderPosition = self.orderPosition

        return actionPhoto
    }
}

extension ActionPhoto
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
