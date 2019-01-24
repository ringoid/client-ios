//
//  ChatViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 24/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import Foundation

struct ChatVMInput
{
    let profile: LMMProfile
    let actionsManager: ActionsManager
    let onClose: (()->())?
}

class ChatViewModel
{
    let input: ChatVMInput
    
    init(_ input: ChatVMInput)
    {
        self.input = input
    }
}
