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
    
    func like(at photoIndex: Int)
    {
        self.input.actionsManager.add(
            [.view(viewCount: 1, viewTimeSec: 1), .like(likeCount: 1)],
            profile: self.input.profile.actionInstance(),
            photo: self.input.profile.photos[photoIndex].actionInstance(),
            source: .newFaces)
    }
    
    func block(at photoIndex: Int, reason: BlockReason)
    {
        self.input.actionsManager.blockActionProtected(
            reason,
            profile: self.input.profile.actionInstance(),
            photo: self.input.profile.photos[photoIndex].actionInstance(),
            source: .newFaces)
    }
}
