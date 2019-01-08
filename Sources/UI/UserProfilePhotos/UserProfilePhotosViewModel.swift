//
//  UserProfilePhotosViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

struct UserProfilePhotosVCInput
{
    let profileManager: UserProfileManager
}

class UserProfilePhotosViewModel
{
    let input: UserProfilePhotosVCInput
    
    init(_ input: UserProfilePhotosVCInput)
    {
        self.input = input
    }
    
    func add(_ photo: UIImage)
    {
        
    }
}
