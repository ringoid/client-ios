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
        self.apiService.getUserOwnPhotos(.small).subscribe(onNext:{ photos in
            print("Uploaded photos: \(photos.count)")
        }).disposed(by: self.disposeBag)
    }
    
    func addPhoto(_ data: Data, filename: String) -> Observable<Void>
    {
        return self.apiService.getPresignedImageUrl(filename, fileExtension: "jpg").flatMap({ apiPhoto -> Observable<Void> in
            
            if let url = URL(string: apiPhoto.url) {
                self.uploader.upload(data, to: url).subscribe(onNext: {
                    print("Photo successfuly uploaded")
                }, onError: { error in
                    print("ERROR: \(error)")
                }).disposed(by: self.disposeBag)
            }
            
            let photo = UserPhoto()
            photo.id = apiPhoto.originId
            photo.url = self.storeTemporary(data).absoluteString
            
            return self.db.add(photo)
        })
    }
    
    // MARK: -
    
    fileprivate func storeTemporary(_ data: Data) -> URL
    {
        let path = FilePath.unique(.temporary)
        try? data.write(to: path.url())
        
        return path.url()
    }
}
