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
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    var profiles: BehaviorRelay<[NewFaceProfile]> = BehaviorRelay<[NewFaceProfile]>(value: [])
    let isFetching: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    init(_ db: DBService, api: ApiService, device: DeviceService, actionsManager: ActionsManager)
    {
        self.db = db
        self.apiService = api
        self.deviceService = device
        self.actionsManager = actionsManager
        
        self.purge()
        
        self.db.fetchNewFaces().bind(to: self.profiles).disposed(by: self.disposeBag)
    }
    
    func refresh() -> Observable<Void>
    {
        self.purge()
        
        return self.fetch()
    }
    
    func fetch() -> Observable<Void>
    {
        self.isFetching.accept(true)
        
        return self.apiService.getNewFaces(self.deviceService.photoResolution, lastActionDate: self.actionsManager.lastActionDate.value).flatMap({ [weak self] profiles -> Observable<Void> in
            
            var localOrderPosition: Int = 0
            
            let localProfiles = self!.filterExisting(profiles).map({ profile -> NewFaceProfile in
                let localPhotos = profile.photos.map({ photo -> Photo in
                    let localPhoto = Photo()
                    localPhoto.id = photo.id
                    localPhoto.setFilepath(FilePath(filename: photo.url, type: .url))
                    localPhoto.orderPosition = localOrderPosition
                    localOrderPosition += 1
                    
                    return localPhoto
                })
                
                let localProfile = NewFaceProfile()
                localProfile.id = profile.id
                localProfile.photos.append(objectsIn: localPhotos)
                
                return localProfile
            })
            
            return self!.db.add(localProfiles)
        }).do(onError: { [weak self] _ in
            self?.isFetching.accept(false)
            }, onCompleted: { [weak self] in
            self?.isFetching.accept(false)
        })
    }
    
    func purge()
    {
        log("New faces: PURGE", level: .high)
        self.db.resetNewFaces().subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func filterExisting(_ incomingProfiles: [ApiProfile]) -> [ApiProfile]
    {
        return incomingProfiles.filter({ incomingProfile in
            for localProfile in self.profiles.value {
                if localProfile.isInvalidated { continue }
                if localProfile.id == incomingProfile.id { return false}
            }
            
            return true
        })
    }
}
