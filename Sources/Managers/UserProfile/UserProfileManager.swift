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
    let storage: XStorageService
    
    var photos: BehaviorRelay<[UserPhoto]> = BehaviorRelay<[UserPhoto]>(value: [])
    var lastPhotoId: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, api: ApiService, uploader: UploaderService, fileService: FileService, device: DeviceService, storage: XStorageService)
    {
        self.db = db
        self.apiService = api
        self.uploader = uploader
        self.fileService = fileService
        self.deviceService = device
        self.storage = storage
        
        self.setupBindings()
        self.db.fetchUserPhotos().bind(to: self.photos).disposed(by: self.disposeBag)
        self.refresh().subscribe().disposed(by: self.disposeBag)
    }
    
    func addPhoto(_ data: Data, filename: String) -> Observable<UserPhoto>
    {
        return self.apiService.getPresignedImageUrl(filename, fileExtension: "jpg").flatMap({ apiPhoto -> Observable<UserPhoto> in
            
            if let url = URL(string: apiPhoto.url) {
                self.uploader.upload(data, to: url).subscribe(onNext: {
                    print("Photo successfuly uploaded")
                }, onError: { error in
                    print("ERROR: \(error)")
                }).disposed(by: self.disposeBag)
            }
            
            let photo = UserPhoto()
            photo.originPhotoId = apiPhoto.originId
            photo.clientPhotoId = apiPhoto.clientId
            photo.setFilepath(self.storeTemporary(data))
            
            return self.db.add(photo).map({ _ -> UserPhoto in
                return photo
            })
        })
    }
    
    func deletePhoto(_ photo: UserPhoto)
    {
        let photoId = photo.id ?? photo.originPhotoId
        let path = photo.filepath()
        self.db.delete([photo]).subscribe(onNext: { [weak self] _ in
            self?.fileService.rm(path)
        }).disposed(by: self.disposeBag)
                
        if let id = photoId {
            self.apiService.deletePhoto(id).subscribe().disposed(by: self.disposeBag)
        }
    }
    
    func refresh() -> Observable<Void>
    {
        return self.apiService.getUserOwnPhotos(self.deviceService.photoResolution).flatMap({ [weak self] photos -> Observable<Void> in
            self?.merge(photos)
            
            return .just(())
        })
    }
    
    // MARK: -
    
    fileprivate let photoKey: String = "profile_last_photo_id"
    
    fileprivate func setupBindings()
    {
        self.storage.object(self.photoKey).subscribe(onNext: { [weak self] obj in
            self?.lastPhotoId.accept(String.create(obj))
            self?.setupLastPhotoBinding()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupLastPhotoBinding()
    {
        self.lastPhotoId.asObservable().subscribe(onNext: { [weak self] id in
            guard let `self` = self else { return }
            guard let photoId = id else {
                self.storage.remove(self.photoKey).subscribe().disposed(by: self.disposeBag)
                
                return
            }
            
            self.storage.store(photoId, key: self.photoKey).subscribe().disposed(by: self.disposeBag)
            
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func storeTemporary(_ data: Data) -> FilePath
    {
        let path = FilePath.unique(.documents)
        try? data.write(to: path.url())
        
        return path
    }
    
    fileprivate func merge(_ incoming: [ApiUserPhoto])
    {
        incoming.forEach({ remoteApiPhoto in
            let remoteId = remoteApiPhoto.originPhotoId
            self.photos.value.forEach { localPhoto in
                guard let localId = localPhoto.originPhotoId else { return }

                if  remoteId == localId {
                    try? localPhoto.realm?.write {
                        localPhoto.likes = remoteApiPhoto.likes
                        localPhoto.isBlocked = remoteApiPhoto.isBlocked
                        localPhoto.id = remoteApiPhoto.id
                    }
                }
            }
        })
    }
}
