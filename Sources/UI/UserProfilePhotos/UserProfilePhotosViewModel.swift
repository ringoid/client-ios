//
//  UserProfilePhotosViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import UIKit

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
    
    func add(_ photo: UIImage) -> Observable<Void>
    {
        guard let data = photo.jpegData(compressionQuality: 1.0) else {
            let error = createError("Can not convert photo to jpeg format", code: 0)
            
            return .error(error)
        }
        
        let path = FilePath.unique(.documents)
        try? data.write(to: path.url())
        return self.input.profileManager.addPhoto(path)
    }
}
