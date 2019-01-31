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
}
