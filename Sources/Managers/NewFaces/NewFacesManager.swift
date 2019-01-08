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
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    var profiles: BehaviorRelay<[NewFaceProfile]> = BehaviorRelay<[NewFaceProfile]>(value: [])
    
    init(_ db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
        
        self.db.fetchNewFaces().bind(to: self.profiles).disposed(by: self.disposeBag)
    }
    
    func refresh() -> Observable<Void>
    {
        return self.apiService.getNewFaces(.small).flatMap({ [weak self] profiles -> Observable<Void> in
            
            let localProfiles = profiles.map({ profile -> NewFaceProfile in
                let localPhotos = profile.photos.map({ photo -> Photo in
                    let localPhoto = Photo()
                    localPhoto.id = photo.id
                    localPhoto.url = photo.url
                    
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
}
