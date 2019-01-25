//
//  UserProfilePhotosViewModel.swift
//  ringoid
//
//  Created by Victor Sukochev on 08/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

struct UserProfilePhotosVCInput
{
    let profileManager: UserProfileManager
    let lmmManager: LMMManager
    let settingsManager: SettingsManager
}

class UserProfilePhotosViewModel
{
    let input: UserProfilePhotosVCInput
    
    var photos: BehaviorRelay<[UserPhoto]>
    {
        return self.input.profileManager.photos
    }
    
    init(_ input: UserProfilePhotosVCInput)
    {
        self.input = input
    }
    
    func add(_ photo: UIImage) -> Observable<Void>
    {
        guard let data = photo.jpegData(compressionQuality: 0.9) else {
            let error = createError("Can not convert photo to jpeg format", type: .hidden)
            
            return .error(error)
        }
        
        return self.input.profileManager.addPhoto(data, filename: UUID().uuidString)
    }
    
    func refresh() -> Observable<Void>
    {
        return self.input.profileManager.refresh().flatMap({ [weak self] _ -> Observable<Void> in
            return self!.input.lmmManager.refresh()
        })
    }
}
