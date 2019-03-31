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
    let navigationManager: NavigationManager
    let newFacesManager: NewFacesManager
    let actionsManager: ActionsManager
    let errorsManager: ErrorsManager
    let promotionManager: PromotionManager
    let device: DeviceService
}

class UserProfilePhotosViewModel
{
    let input: UserProfilePhotosVCInput
    
    let photos: BehaviorRelay<[UserPhoto]> = BehaviorRelay<[UserPhoto]>(value: [])
    
    var lastPhotoId: BehaviorRelay<String?>
    {
        return self.input.profileManager.lastPhotoId
    }
        
    var isAuthorized: BehaviorRelay<Bool>
    {
        return self.input.settingsManager.isAuthorized
    }
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ input: UserProfilePhotosVCInput)
    {
        self.input = input
        
        self.setupBindings()
    }
    
    func add(_ photo: UIImage) -> Observable<UserPhoto>
    {
        guard let data = photo.jpegData(compressionQuality: 0.9) else {
            let error = createError("Can not convert photo to jpeg format", type: .hidden)
            
            return .error(error)
        }
        
        return self.input.profileManager.addPhoto(data, filename: UUID().uuidString)
    }
    
    func refresh() -> Observable<Void>
    {
        if self.photos.value.count != 0 {
            self.input.newFacesManager.purgeInBackground()
            self.input.lmmManager.refreshInBackground(.profile)
        }

        return self.input.profileManager.refresh()
    }
    
    func delete(_ photo: UserPhoto)
    {
        self.input.profileManager.deletePhoto(photo)
    }
    
    func moveToSearch()
    {
        self.input.navigationManager.mainItem.accept(.searchAndFetch)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.profileManager.photos.asObservable().subscribe(onNext: { [weak self] updatedPhotos in
            self?.photos.accept(updatedPhotos.filter({ !$0.isBlocked }))
        }).disposed(by: self.disposeBag)
    }
}
