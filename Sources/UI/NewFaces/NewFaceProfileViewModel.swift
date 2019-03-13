//
//  NewFaceProfileViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 10/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct NewFaceProfileVMInput
{
    let profile: Profile
    let actionsManager: ActionsManager
    let sourceType: SourceFeedType
}

class NewFaceProfileViewModel
{
    let input: NewFaceProfileVMInput
    
    init(_ input: NewFaceProfileVMInput)
    {
        self.input = input
    }
    
    func block(at photoIndex: Int, reason: BlockReason)
    {
        guard let actionProfile = self.input.profile.actionInstance() else { return }
        
        self.input.actionsManager.blockActionProtected(
            reason,
            profile: actionProfile,
            photo: actionProfile.orderedPhotos()[photoIndex],
            source: .newFaces)
    }
}
