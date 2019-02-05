//
//  ActionPhoto.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class ActionPhoto: Photo
{
    
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
        
        if self.realm?.isInWriteTransaction == true {
            self.realm?.add(actionPhoto)
        } else {            
            try? self.realm?.write { [weak self] in
                self?.realm?.add(actionPhoto)
            }
        }
        
        return actionPhoto
    }
}
