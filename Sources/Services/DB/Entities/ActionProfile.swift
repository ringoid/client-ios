//
//  ActionProfile.swift
//  ringoid
//
//  Created by Victor Sukochev on 28/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift

class ActionProfile: Profile
{
    
}

extension Profile
{
    func actionInstance() -> ActionProfile
    {
        let actionProfile = ActionProfile()
        actionProfile.id = self.id
        actionProfile.photos.append(objectsIn: self.photos)
        
        try? self.realm?.write { [weak self] in
            self?.realm?.add(actionProfile)
        }
        
        return actionProfile
    }
}
