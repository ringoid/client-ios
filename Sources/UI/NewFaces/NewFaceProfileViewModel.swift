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
}

class NewFaceProfileViewModel
{
    let input: NewFaceProfileVMInput
    
    init(_ input: NewFaceProfileVMInput)
    {
        self.input = input
    }
}
