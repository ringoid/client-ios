//
//  UserProfileManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 03/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class UserProfileManager
{
    let db: DBService
    let apiService: ApiService
    let uploader: UploaderService
    
    var photos: BehaviorRelay<[UserPhoto]> = BehaviorRelay<[UserPhoto]>(value: [])
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, api: ApiService, uploader: UploaderService)
    {
        self.db = db
        self.apiService = api
        self.uploader = uploader
        
        self.db.fetchUserPhotos().bind(to: self.photos).disposed(by: self.disposeBag)
    }
    
    func addPhoto(_ path: FilePath) -> Observable<Void>
    {
        return self.apiService.getPresignedImageUrl(path.filename, fileExtension: "jpg").flatMap({ apiPhoto -> Observable<Void> in
            
            if let url = URL(string: apiPhoto.url) {
                _ = self.uploader.upload(path.url(), to: url)
            }
            
            let photo = UserPhoto()
            photo.id = apiPhoto.originId
            photo.url = path.url().absoluteString
            return self.db.add(photo)
        })
    }
}