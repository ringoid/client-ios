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
    let actionsManager: ActionsManager
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    var profiles: BehaviorRelay<[NewFaceProfile]> = BehaviorRelay<[NewFaceProfile]>(value: [])
    
    init(_ db: DBService, api: ApiService, actionsManager: ActionsManager)
    {
        self.db = db
        self.apiService = api
        self.actionsManager = actionsManager
        
        self.db.fetchNewFaces().bind(to: self.profiles).disposed(by: self.disposeBag)
    }
    
    func refresh() -> Observable<Void>
    {
        self.db.resetNewFaces().subscribe().disposed(by: self.disposeBag)
        return self.fetch()
    }
    
    func fetch() -> Observable<Void>
    {
        return self.apiService.getNewFaces(.small, lastActionDate: self.actionsManager.lastActionDate).flatMap({ [weak self] profiles -> Observable<Void> in
            
            let localProfiles = self!.filterExisting(profiles).map({ profile -> NewFaceProfile in
                let localPhotos = profile.photos.map({ photo -> Photo in
                    let localPhoto = Photo()
                    localPhoto.id = photo.id
                    localPhoto.setFilepath(FilePath(filename: photo.url, type: .url))
                    
                    return localPhoto
                })
                
                let localProfile = NewFaceProfile()
                localProfile.id = profile.id
                localProfile.photos.append(objectsIn: localPhotos)
                
                return localProfile
            })
            
            return self!.db.add(localProfiles)
        })
    }
    
    // MARK: -
    
    fileprivate func filterExisting(_ incomingProfiles: [ApiProfile]) -> [ApiProfile]
    {
        return incomingProfiles.filter({ incomingProfile in
            for localProfile in self.profiles.value {
                if localProfile.id == incomingProfile.id { return false}
            }
            
            return true
        })
    }
}
