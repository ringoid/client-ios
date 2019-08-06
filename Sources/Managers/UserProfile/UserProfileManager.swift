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
    let lmm: LMMManager
    let filter: FilterManager
    
    let photos: BehaviorRelay<[UserPhoto]> = BehaviorRelay<[UserPhoto]>(value: [])
    let lastPhotoId: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    let isBlocked: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var isPhotosAdded: Bool
    {
        return !self.photos.value.filter({ !$0.isBlocked }).isEmpty
    }
    
    var gender: BehaviorRelay<Sex?> =  BehaviorRelay<Sex?>(value: nil)
    var yob: BehaviorRelay<Int?> =  BehaviorRelay<Int?>(value: nil)
    var creationDate: BehaviorRelay<Date?> = BehaviorRelay<Date?>(value: nil)
    
    var status: BehaviorRelay<OnlineStatus?> = BehaviorRelay<OnlineStatus?>(value: nil)
    var statusText: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    var distanceText: BehaviorRelay<String?> = BehaviorRelay<String?>(value: nil)
    
    let profile: BehaviorRelay<UserProfile?> = BehaviorRelay<UserProfile?>(value: nil)
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, api: ApiService, uploader: UploaderService, fileService: FileService, device: DeviceService, storage: XStorageService, lmm: LMMManager, filter: FilterManager)
    {
        self.db = db
        self.apiService = api
        self.uploader = uploader
        self.fileService = fileService
        self.deviceService = device
        self.storage = storage
        self.lmm = lmm
        self.filter = filter
        
        self.checkProfile()
        self.loadProfileInfo()
        self.setupBindings()
    }
    
    func addPhoto(_ data: Data, filename: String) -> Observable<UserPhoto>
    {
        // Storing local data
        let photo = UserPhoto()
        photo.clientId = filename
        photo.setFilepath(self.storeTemporary(data))
        
        // Requesting remote url
        self.apiService.getPresignedImageUrl(filename, fileExtension: "jpg").subscribe(onNext: { [weak self] apiPhotoPlaceholder in
            
            // Starting data upload
            if let url = URL(string: apiPhotoPlaceholder.url) {
                self!.uploader.upload(data, to: url).subscribe(onNext: {
                    log("Photo successfuly uploaded", level: .high)
                }, onError: { error in
                    log("ERROR: \(error)", level: .high)
                }).disposed(by: self!.disposeBag)
            }
            
            // Updating origin id
            self!.db.userPhoto(filename).asObservable().subscribe(onNext: { photo in
                guard let photo = photo else { return }
                photo.write({ obj in
                    (obj as? UserPhoto)?.originId = apiPhotoPlaceholder.originId
                })
                
            }).disposed(by: self!.disposeBag)
        }).disposed(by: self.disposeBag)
        
        return self.db.add(photo).asObservable().map({ _ -> UserPhoto in
            let updatedPhotos = self.photos.value
            updatedPhotos[0..<(updatedPhotos.count - 1)].forEach({ oldPhoto in
                self.db.updateOrder(oldPhoto, silently: false)
            })
            
            return photo
        })
    }
    
    func deletePhoto(_ photo: UserPhoto)
    {
        guard let index = self.photos.value.index(of: photo) else { return }
        
        let photoId = photo.id ?? photo.originId
        
        if index > 0 {
            let prevPhoto = self.photos.value[index - 1]
            let prevPhotoId = prevPhoto.originId
            self.lastPhotoId.accept(prevPhotoId)
        }
        
        let path = photo.filepath()
        self.db.delete([photo]).subscribe(onSuccess: { [weak self] _ in
            self?.fileService.rm(path)
        }).disposed(by: self.disposeBag)
                
        if let id = photoId {
            guard let url = path.url() else { return }
            
            self.uploader.cancel(url)
            self.apiService.deletePhoto(id).subscribe(onNext:{
                AnalyticsManager.shared.send(.deletedPhoto)
            }).disposed(by: self.disposeBag)
        }
    }
    
    func createProfile()
    {
        self.db.add(UserProfile()).subscribe().disposed(by: self.disposeBag)
    }
    
    func updateProfile()
    {
        guard let profile = self.profile.value else { return }
        
        let apiProfile = ApiUserProfileInfo(
            property: profile.property.value ?? 0,
            transport: profile.transport.value ?? 0,
            income: profile.income.value ?? 0,
            height: profile.height.value ?? 0,
            educationLevel: profile.educationLevel.value ?? 0,
            hairColor: profile.hairColor.value ?? 0,
            children: profile.children.value ?? 0,
            name: profile.name ?? "unknown",
            jobTitle: profile.jobTitle ?? "unknown",
            company: profile.company ?? "unknown",
            education: profile.education ?? "unknown",
            about: profile.about ?? "unknown",
            instagram: profile.instagram ?? "unknown",
            tikTok: profile.tikTok ?? "unknown",
            whereLive: profile.whereLive ?? "unknown",
            whereFrom: profile.whereFrom ?? "unknown"
        )
        
        self.apiService.updateProfile(apiProfile).subscribe().disposed(by: self.disposeBag)
    }
    
    func refresh() -> Observable<Void>
    {
        return self.apiService.getUserOwnPhotos(self.deviceService.photoResolution).flatMap({ [weak self] profile -> Observable<Void> in
            self?.merge(profile.photos)
            self?.status.accept(profile.status?.onlineStatus())
            self?.statusText.accept(profile.statusText)
            self?.distanceText.accept(profile.distanceText) 
            
            return .just(())
        })
    }
    
    func refreshInBackground()
    {
        self.refresh().subscribe().disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        guard let profile = self.profile.value, !profile.isInvalidated else { return }
            
        self.db.delete([profile]).subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate let photoKey: String = "profile_last_photo_id"
    
    fileprivate func setupBindings()
    {
        self.db.userPhotos().subscribeOn(MainScheduler.instance).bind(to: self.photos).disposed(by: self.disposeBag)
        
        self.storage.object(self.photoKey).subscribe(onSuccess: { [weak self] obj in
            self?.lastPhotoId.accept(String.create(obj))
            self?.setupLastPhotoBinding()
        }).disposed(by: self.disposeBag)
        
        self.photos.subscribe(onNext:{ [weak self] photos in
            guard let `self` = self else { return }
            guard photos.filter({ !$0.isBlocked }).count == 0 else {
                self.lmm.contentShouldBeHidden = false
                
                return
            }

            self.lmm.contentShouldBeHidden = true            
        }).disposed(by: self.disposeBag)
        
        self.gender.subscribe(onNext: { [weak self] value in
            guard let value = value else { return }
            
            UserDefaults.standard.setValue(value.rawValue, forKey: "profile_sex")
            UserDefaults.standard.synchronize()
            
            AnalyticsManager.shared.gender = value
            
            self?.checkFilterDefaults()
        }).disposed(by: self.disposeBag)
        
        self.yob.subscribe(onNext: { [weak self] value in
            guard let value = value else { return }
            
            UserDefaults.standard.setValue(value, forKey: "profile_yob")
            UserDefaults.standard.synchronize()
            
            AnalyticsManager.shared.yob = value
            
            self?.checkFilterDefaults()
        }).disposed(by: self.disposeBag)
        
        self.creationDate.subscribe(onNext: { value in
            guard let value = value else { return }
            
            UserDefaults.standard.setValue(value.timeIntervalSince1970, forKey: "profile_creation_date")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        self.db.userProfile().subscribe(onNext: { [weak self] userProfile in
            self?.profile.accept(userProfile)
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
        
        if let url = path.url() {
            try? data.write(to: url)
        }
        
        return path
    }
    
    fileprivate func merge(_ incoming: [ApiUserPhoto])
    {
        var isBlokedRemotely = false
        
        incoming.forEach({ remoteApiPhoto in
            let remoteId = remoteApiPhoto.originPhotoId
            
            self.photos.value.forEach { localPhoto in
                guard let localId = localPhoto.originId else { return }

                if  remoteId == localId {
                    try? localPhoto.realm?.write {
                        self.fileService.rm(localPhoto.filepath())
                        
                        if !localPhoto.isBlocked && remoteApiPhoto.isBlocked {
                            isBlokedRemotely = true
                        }
                        
                        localPhoto.likes = remoteApiPhoto.likes
                        localPhoto.isBlocked = remoteApiPhoto.isBlocked
                        localPhoto.id = remoteApiPhoto.id
                        localPhoto.setFilepath(FilePath(filename: remoteApiPhoto.url, type: .url))
                        self.db.updateOrder(localPhoto, silently: false)
                    }
                }
            }
        })
        
        self.isBlocked.accept(isBlokedRemotely)
    }
    
    fileprivate func loadProfileInfo()
    {
       
        if  let sexStr = UserDefaults.standard.string(forKey: "profile_sex"), let genderValue = Sex(rawValue: sexStr) {
            self.gender.accept(genderValue)
        }
        
        let yobValue = UserDefaults.standard.integer(forKey: "profile_yob")
        self.yob.accept(yobValue != 0 ? yobValue : nil)
        
        let creationTimestamp = UserDefaults.standard.double(forKey: "profile_creation_date")        
        if creationTimestamp > 1.0 {
            self.creationDate.accept(Date(timeIntervalSince1970: creationTimestamp))
        }
    }
    
    fileprivate func checkProfile()
    {
        if self.profile.value == nil {
            self.createProfile()
        }
    }
    
    fileprivate func checkFilterDefaults()
    {
        guard let yob = self.yob.value, let gender = self.gender.value else { return }
        
        let age = Calendar.current.component(.year, from: Date()) - yob
        self.filter.checkDefaultValues(gender, age: age)
    }
}
