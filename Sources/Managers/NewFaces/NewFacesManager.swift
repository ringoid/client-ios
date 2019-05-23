//
//  NewFacesManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 07/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class NewFacesManager
{
    let db: DBService
    let apiService: ApiService
    let deviceService: DeviceService
    let actionsManager: ActionsManager
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    var profiles: BehaviorRelay<[NewFaceProfile]> = BehaviorRelay<[NewFaceProfile]>(value: [])
    let isFetching: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    init(_ db: DBService, api: ApiService, device: DeviceService, actionsManager: ActionsManager)
    {
        self.db = db
        self.apiService = api
        self.deviceService = device
        self.actionsManager = actionsManager
        
        self.purgeInBackground()
        
        self.setupBindings()
    }
    
    func refresh() -> Observable<Void>
    {
        return self.purge().asObservable().flatMap({ _ -> Observable<Void> in
            return self.fetch()
        })
    }
    
    func fetch() -> Observable<Void>
    {
        return self.apiService.getNewFaces(self.deviceService.photoResolution, lastActionDate: self.actionsManager.lastActionDate.value).flatMap({ [weak self] profiles -> Observable<Void> in
            
            var localOrderPosition: Int = 0
            
            let uniqueProfiles = self!.filterDuplications(profiles)
            let localProfiles = self!.filterExisting(uniqueProfiles).map({ profile -> NewFaceProfile in
                let localPhotos = profile.photos.map({ photo -> Photo in
                    let localPhoto = Photo()
                    localPhoto.id = photo.id
                    localPhoto.setFilepath(FilePath(filename: photo.url, type: .url))
                    localPhoto.setThumbnailFilepath(FilePath(filename: photo.thumbnailUrl, type: .url))
                    localPhoto.orderPosition = localOrderPosition
                    localOrderPosition += 1
                    
                    return localPhoto
                })
                
                let localProfile = NewFaceProfile()
                localProfile.id = profile.id
                localProfile.photos.append(objectsIn: localPhotos)
                
                return localProfile
            })
            
            return self!.db.add(localProfiles).asObservable()
        }).delay(0.05, scheduler: MainScheduler.instance).single().do(onNext: { [weak self] _ in
            self?.isFetching.accept(false)
            }, onError: { [weak self] _ in
            self?.isFetching.accept(false)
        })
    }
    
    func purge() -> Single<Void>
    {
        log("New faces: PURGE", level: .high)
        
        return self.db.resetNewFaces()
    }
    
    func purgeInBackground()
    {
        return self.purge().subscribe().disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.profiles.accept([])
        
        self.disposeBag = DisposeBag()
        self.setupBindings()
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.db.newFaces().subscribeOn(MainScheduler.instance).bind(to: self.profiles).disposed(by: self.disposeBag)
    }
    
    fileprivate func filterExisting(_ incomingProfiles: [ApiProfile]) -> [ApiProfile]
    {
        return incomingProfiles.filter({ incomingProfile in
            for localProfile in self.profiles.value {
                if self.actionsManager.isViewed(incomingProfile.id) { return false }
                if localProfile.isInvalidated { continue }
                if localProfile.id == incomingProfile.id { return false}
            }
            
            return true
        })
    }
    
    fileprivate func filterDuplications(_ incomingProfiles: [ApiProfile]) -> [ApiProfile]
    {
        var duplicationsMap: [String: Bool] = [:]
        var result: [ApiProfile] = []
        
        incomingProfiles.forEach { profile in
            guard duplicationsMap[profile.id] == nil else { return }
            
            duplicationsMap[profile.id] = true
            result.append(profile)
        }
        
        return result
    }
}
