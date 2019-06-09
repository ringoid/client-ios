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
    let location: LocationManager
    let scenario: AnalyticsScenarioManager
}

class UserProfilePhotosViewModel
{
    let input: UserProfilePhotosVCInput
    
    let photos: BehaviorRelay<[UserPhoto]> = BehaviorRelay<[UserPhoto]>(value: [])
    var isBlocked: BehaviorRelay<Bool>
    {
        return self.input.profileManager.isBlocked
    }
    
    var status: BehaviorRelay<OnlineStatus?>
    {
        return self.input.profileManager.status
    }
    
    var statusText: BehaviorRelay<String?>
    {
        return self.input.profileManager.statusText
    }
    
    var distanceText: BehaviorRelay<String?>
    {
        return self.input.profileManager.distanceText
    }
    
    var lastPhotoId: BehaviorRelay<String?>
    {
        return self.input.profileManager.lastPhotoId
    }
        
    var isAuthorized: BehaviorRelay<Bool>
    {
        return self.input.settingsManager.isAuthorized
    }
    
    var lmmCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)

    var isLocationDenied: Bool
    {
        return self.input.location.isDenied
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
    
    func registerLocationsIfNeeded() -> Bool
    {
        guard !self.input.location.isGranted.value else { return true }
        
        self.input.location.requestPermissionsIfNeeded()
        
        return false
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.input.profileManager.photos.asObservable().subscribe(onNext: { [weak self] updatedPhotos in
            self?.photos.accept(updatedPhotos.filter({ !$0.isBlocked }))
        }).disposed(by: self.disposeBag)
        
        // LMM count
        
        self.input.lmmManager.likesYou.subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            let manager = self.input.lmmManager
            var count = profiles.count + manager.matches.value.count + manager.messages.value.count
            count += manager.notificationsProfilesCount.value
            self.lmmCount.accept(count)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.matches.subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            let manager = self.input.lmmManager
            var count = profiles.count + manager.likesYou.value.count + manager.messages.value.count
            count += manager.notificationsProfilesCount.value
            self.lmmCount.accept(count)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.messages.subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            let manager = self.input.lmmManager
            var count = profiles.count + manager.likesYou.value.count + manager.matches.value.count
            count += manager.notificationsProfilesCount.value
            self.lmmCount.accept(count)
        }).disposed(by: self.disposeBag)
        
        self.input.lmmManager.notificationsProfilesCount.subscribe(onNext: { [weak self] notificationsCount in
            guard let `self` = self else { return }
            
            let manager = self.input.lmmManager
            var count = manager.messages.value.count + manager.likesYou.value.count + manager.matches.value.count
            count += notificationsCount
            self.lmmCount.accept(count)
        }).disposed(by: self.disposeBag)
    }
}
