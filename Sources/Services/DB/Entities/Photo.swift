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
    @objc dynamic var path: String!
    @objc dynamic var pathType: Int = 0
    @objc dynamic var thumbnailPath: String!
    @objc dynamic var thumbnailPathType: Int = 0
    @objc dynamic var isLiked: Bool = false
}

extension Photo
{
    func filepath() -> FilePath
    {
        let type = FileType(rawValue: self.pathType)!
        
        return FilePath(filename: self.path, type: type)
    }
    
    func thumbnailFilepath() -> FilePath
    {
        let type = FileType(rawValue: self.thumbnailPathType)!
        
        return FilePath(filename: self.thumbnailPath, type: type)
    }
    
    func setFilepath(_ filepath: FilePath)
    {
        self.path = filepath.filename
        self.pathType = filepath.type.rawValue
    }
    
    func setThumbnailFilepath(_ filepath: FilePath)
    {
        self.thumbnailPath = filepath.filename
        self.thumbnailPathType = filepath.type.rawValue
    }
}
