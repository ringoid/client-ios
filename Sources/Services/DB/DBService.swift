//
//  DBService.swift
//  ringoid
//
//  Created by Victor Sukochev on 04/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RealmSwift
import RxRealm
import RxSwift

class DBService
{
    fileprivate let realm: Realm
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var currentOrderPosition: Int = 0
    
    // Observers
    fileprivate var newFacesObservable: Observable<[NewFaceProfile]>!
    fileprivate var newFacesObserver: AnyObserver<[NewFaceProfile]>?
    
    fileprivate var likesYouObservable: Observable<[LMMProfile]>!
    fileprivate var likesYouObserver: AnyObserver<[LMMProfile]>?
    
    fileprivate var matchesObservable: Observable<[LMMProfile]>!
    fileprivate var matchesObserver: AnyObserver<[LMMProfile]>?
    
    fileprivate var messagesObservable: Observable<[LMMProfile]>!
    fileprivate var messagesObserver: AnyObserver<[LMMProfile]>?
    
    fileprivate var userPhotosObservable: Observable<[UserPhoto]>!
    fileprivate var userPhotosObserver: AnyObserver<[UserPhoto]>?
    
    init()
    {
        let version: UInt64 = 3
        let config = Realm.Configuration(schemaVersion: version, deleteRealmIfMigrationNeeded: true)
        
        self.realm = try! Realm(configuration: config)
        self.currentOrderPosition = UserDefaults.standard.integer(forKey: "db_service_order_position_key")
        self.cleanDeletedObjects()
        self.setupObservers()
    }
    
    // MARK: - New Faces
    func newFaces() -> Observable<[NewFaceProfile]>
    {
        return self.newFacesObservable
    }

    // MARK: - LMM
    
    func likesYou() -> Observable<[LMMProfile]>
    {
        return self.likesYouObservable
    }
    
    func matches() -> Observable<[LMMProfile]>
    {
        return self.matchesObservable
    }
    
    func messages() -> Observable<[LMMProfile]>
    {
        return self.messagesObservable
    }
    
    func blockProfile(_ id: String)
    {
        let blockedProfile = BlockedProfile()
        blockedProfile.id = id
        self.add(blockedProfile).subscribe(onSuccess: { [weak self] _ in
            self?.removeProfiles(id)
        }).disposed(by: self.disposeBag)
    }
    
    func markProfileAsSeen(_ id: String)
    {
        let predicate = NSPredicate(format: "id = %@ AND isDeleted = false", id)
        guard let lmmProfile = self.realm.objects(LMMProfile.self).filter(predicate).first else { return }
        guard lmmProfile.notSeen else { return }
        guard lmmProfile.messages.count == 0 else { return }
        
        if self.realm.isInWriteTransaction {
            lmmProfile.notSeen = false
            self.checkObjectsForUpdates([lmmProfile])
        } else {
            try? self.realm.write {
                lmmProfile.notSeen = false
                self.checkObjectsForUpdates([lmmProfile])
            }
        }
    }
    
    func forceMarkAsSeen(_ profile: LMMProfile)
    {
        if self.realm.isInWriteTransaction {
            profile.notSeen = false
            self.checkObjectsForUpdates([profile])
        } else {
            try? self.realm.write {
                profile.notSeen = false
                self.checkObjectsForUpdates([profile])
            }
        }
    }
    
    func forceUpdateLMM()
    {
        self.updateLikesYou()
        self.updateMatches()
        self.updateMessages()
    }

    // MARK: - User
    
    func userPhotos() -> Observable<[UserPhoto]>
    {
        return self.userPhotosObservable
    }
    
    func userPhoto(_ clientId: String) -> Single<UserPhoto?>
    {
        let predicate = NSPredicate(format: "clientId = %@ AND isDeleted = false", clientId)
        let photo = self.realm.objects(UserPhoto.self).filter(predicate).first
        
        return .just(photo)
    }
    
    // MARK: - Actions
    
    func actions() -> Observable<[Action]>
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let actions = self.realm.objects(Action.self).filter(predicate)
        
        return Observable.array(from: actions)
    }
    
    // MARK: - Common
    
    func add(_ object: DBServiceObject) -> Single<Void>
    {
        return self.add([object])
    }
    
    func add(_ objects: [DBServiceObject]) -> Single<Void>
    {
        objects.forEach { object in
            object.orderPosition = self.currentOrderPosition
            self.currentOrderPosition += 1
        }
        
        UserDefaults.standard.set(self.currentOrderPosition, forKey: "db_service_order_position_key")
        UserDefaults.standard.synchronize()
        
        let objectsToAdd = self.filterBlocked(objects)
        
        return Single<Void>.create { single -> Disposable in
            if self.realm.isInWriteTransaction {
                self.realm.add(objectsToAdd)
                self.checkObjectsForUpdates(objectsToAdd)
                single(.success(()))
            } else {
                try? self.realm.write {
                    self.realm.add(objectsToAdd)
                    self.checkObjectsForUpdates(objectsToAdd)
                }

                single(.success(()))
            }
            
            return Disposables.create()
        }
    }
    
    func updateOrder(_ object: DBServiceObject)
    {
        self.updateOrder([object])
    }
    
    func updateOrder(_ objects: [DBServiceObject])
    {
        if self.realm.isInWriteTransaction {
            objects.forEach { object in
                object.orderPosition = self.currentOrderPosition
                self.currentOrderPosition += 1
            }
 
            self.checkObjectsForUpdates(objects)
        } else {
            try? self.realm.write {
                objects.forEach { object in
                    object.orderPosition = self.currentOrderPosition
                    self.currentOrderPosition += 1
                }
                
                self.checkObjectsForUpdates(objects)
            }
        }
    }
    
    func delete(_ objects: [DBServiceObject]) -> Single<Void>
    {
        return Single<Void>.create { [weak self] single -> Disposable in
            guard let `self` = self else { return Disposables.create() }
            
            if self.realm.isInWriteTransaction {
                objects.forEach({ $0.isDeleted = true })
                self.checkObjectsForUpdates(objects)
                single(.success(()))
            } else {
                try? self.realm.write {
                    objects.forEach({ $0.isDeleted = true })
                     self.checkObjectsForUpdates(objects)
                }

                single(.success(()))
            }

            return Disposables.create()
        }
    }
    
    // MARK: - Resets
    
    func resetLMM() -> Single<Void>
    {
        let profiles = self.realm.objects(LMMProfile.self)
        return self.delete(Array(profiles))
    }
    
    func resetNewFaces() -> Single<Void>
    {
        let profiles = self.realm.objects(NewFaceProfile.self)
        return self.delete(Array(profiles))
    }
    
    func reset()
    {
        self.newFacesObserver?.onNext([])
        self.likesYouObserver?.onNext([])
        self.matchesObserver?.onNext([])
        self.messagesObserver?.onNext([])
        self.userPhotosObserver?.onNext([])
        
        try? self.realm.write {
            self.realm.deleteAll()
        }
        
        self.currentOrderPosition = 0
        UserDefaults.standard.removeObject(forKey: "db_service_order_position_key")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: -
    
    fileprivate func setupObservers()
    {
        self.newFacesObservable = Observable<[NewFaceProfile]>.create({ [weak self] observer -> Disposable in
            self?.newFacesObserver = observer
            self?.updateNewFaces()
            
            return Disposables.create()
        })
        
        self.likesYouObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.likesYouObserver = observer
            self?.updateLikesYou()
            
            return Disposables.create()
        })
        
        self.matchesObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.matchesObserver = observer
            self?.updateMatches()
            
            return Disposables.create()
        })
        
        self.messagesObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.messagesObserver = observer
            self?.updateMessages()
            
            return Disposables.create()
        })
        
        self.userPhotosObservable = Observable<[UserPhoto]>.create({ [weak self] observer -> Disposable in
            self?.userPhotosObserver = observer
            self?.updateUserPhotos()
            
            return Disposables.create()
        })
    }
    
    fileprivate func updateNewFaces()
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let profiles = self.realm.objects(NewFaceProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.newFacesObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateLikesYou()
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.likesYou.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.likesYouObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateMatches()
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.matches.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.matchesObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateMessages()
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.messages.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.messagesObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateUserPhotos()
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let photos = self.realm.objects(UserPhoto.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.userPhotosObserver?.onNext(photos.toArray())
    }
    
    fileprivate func checkObjectsForUpdates(_ objects: [DBServiceObject])
    {
        var shouldUpdateNewFaces: Bool = false
        var shouldUpdateLikesYou: Bool = false
        var shouldUpdateMessages: Bool = false
        var shouldUpdateMatches: Bool = false
        var shouldUpdateUserPhotos: Bool = false
        
        objects.forEach { object in
            if let _ = object as? NewFaceProfile { shouldUpdateNewFaces = true }
            if let _ = object as? UserPhoto { shouldUpdateUserPhotos = true }
            
            if let profile = object as? LMMProfile {
                if profile.type == FeedType.likesYou.rawValue { shouldUpdateLikesYou = true }
                if profile.type == FeedType.matches.rawValue { shouldUpdateMatches = true }
                if profile.type == FeedType.messages.rawValue { shouldUpdateMessages = true }
            }
        }
        
        if shouldUpdateNewFaces { self.updateNewFaces() }
        if shouldUpdateLikesYou { self.updateLikesYou() }
        if shouldUpdateMessages { self.updateMessages() }
        if shouldUpdateMatches { self.updateMatches() }
        if shouldUpdateUserPhotos { self.updateUserPhotos() }
    }
    
    fileprivate func removeProfiles(_ id: String)
    {
        var objectsToRemove: [DBServiceObject] = []
        let predicate = NSPredicate(format: "id = %@ AND isDeleted = false", id)
        objectsToRemove.append(contentsOf: Array(self.realm.objects(NewFaceProfile.self).filter(predicate)))
        objectsToRemove.append(contentsOf: Array(self.realm.objects(LMMProfile.self).filter(predicate)))
        self.delete(objectsToRemove).subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func filterBlocked(_ objects: [DBServiceObject]) -> [DBServiceObject]
    {
        let blockedIds = Array(self.realm.objects(BlockedProfile.self).map({ $0.id }))
        
        return objects.filter({ object in
            guard let profile = object as? Profile else { return true }
            
            for blockedId in blockedIds {
                if profile.id == blockedId { return false }
            }
            
            return true
        })
    }
    
    fileprivate func cleanDeletedObjects()
    {
        var objectsToDelete: [Object] = []
        let predicate = NSPredicate(format: "isDeleted = true")
        objectsToDelete.append(contentsOf: Array(self.realm.objects(Action.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(ActionPhoto.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(ActionProfile.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(Profile.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(Photo.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(UserPhoto.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(NewFaceProfile.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(LMMProfile.self).filter(predicate)))
        objectsToDelete.append(contentsOf: Array(self.realm.objects(Message.self).filter(predicate)))

        try? self.realm.write {
            self.realm.delete(objectsToDelete)
        }
    }
}
