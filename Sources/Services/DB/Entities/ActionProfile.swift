//
//  ActionProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class ActionProfile: DBServiceObject
{
    @objc dynamic var id: String!
    let photos: List<ActionPhoto> = List<ActionPhoto>()
    
    func orderedPhotos() -> [ActionPhoto]
    {
        guard !self.isInvalidated else { return []  }
        
        return Array(self.photos.sorted(byKeyPath: "orderPosition"))
    }
}

extension Profile
{
    func actionInstance() -> ActionProfile?
    {
        guard !self.isInvalidated else { return nil }
        
        let actionProfile = ActionProfile()
        actionProfile.id = self.id
        actionProfile.photos.append(objectsIn: self.photos.map({ $0.actionInstance() }))        
        
        if self.realm?.isInWriteTransaction == true {
            self.realm?.add(actionProfile)
        } else {
            try? self.realm?.write { [weak self] in
                self?.realm?.add(actionProfile)
            }
        }
        
        return actionProfile
    }
}
