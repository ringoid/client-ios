//
//  MainLMMProfileViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct MainLMMProfileVMInput
{
    let profile: LMMProfile
    let feedType: LMMType
    let actionsManager: ActionsManager
    let initialIndex: Int
}

class MainLMMProfileViewModel
{
    let input: MainLMMProfileVMInput
    
    init(_ input: MainLMMProfileVMInput)
    {
        self.input = input
    }
    
    func like(at photoIndex: Int)
    {
        self.input.actionsManager.add(
            [.view(viewCount: 1, viewTimeSec: 1), .like(likeCount: 1)],
            profile: self.input.profile.actionInstance(),
            photo: self.input.profile.photos[photoIndex].actionInstance(),
            source: self.input.feedType.sourceType())
    }
    
    func block(at photoIndex: Int, reason: BlockReason)
    {
        self.input.actionsManager.blockActionProtected(
            reason,
            profile: self.input.profile.actionInstance(),
            photo: self.input.profile.photos[photoIndex].actionInstance(),
            source: self.input.feedType.sourceType())
    }
}
