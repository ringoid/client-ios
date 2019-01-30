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
    let fileService: FileService
    let deviceService: DeviceService
    
    var photos: BehaviorRelay<[UserPhoto]> = BehaviorRelay<[UserPhoto]>(value: [])
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, api: ApiService, uploader: UploaderService, fileService: FileService, device: DeviceService)
    {
        self.db = db
        self.apiService = api
        self.uploader = uploader
        self.fileService = fileService
        self.deviceService = device
        
        self.db.fetchUserPhotos().bind(to: self.photos).disposed(by: self.disposeBag)
        self.refresh().subscribe().disposed(by: self.disposeBag)
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
            photo.setFilepath(self.storeTemporary(data))
            
            return self.db.add(photo)
        })
    }
    
    func deletePhoto(_ photo: UserPhoto)
    {
        let path = photo.filepath()
        let id = photo.id!
        
        self.db.delete([photo]).subscribe(onNext: { [weak self] _ in
            self?.fileService.rm(path)
        }).disposed(by: self.disposeBag)
        
        self.apiService.deletePhoto(id).subscribe().disposed(by: self.disposeBag)
    }
    
    func refresh() -> Observable<Void>
    {
        return self.apiService.getUserOwnPhotos(self.deviceService.photoResolution).flatMap({ [weak self] photos -> Observable<Void> in
            self?.merge(photos)
            
            return .just(())
        })
    }
    
    // MARK: -
    
    fileprivate func storeTemporary(_ data: Data) -> FilePath
    {
        let path = FilePath.unique(.documents)
        try? data.write(to: path.url())
        
        return path
    }
    
    fileprivate func merge(_ incoming: [ApiPhoto])
    {
        incoming.forEach({ remoteApiPhoto in
            self.photos.value.forEach { localPhoto in
                if remoteApiPhoto.id == localPhoto.id {
                    try? localPhoto.realm?.write {
                        localPhoto.likes = remoteApiPhoto.likes
                    }
                }
            }
        })
    }
}
