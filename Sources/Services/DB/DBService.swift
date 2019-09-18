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
    
    fileprivate var messagesObservable: Observable<[LMMProfile]>!
    fileprivate var messagesObserver: AnyObserver<[LMMProfile]>?
    
    fileprivate var inboxObservable: Observable<[LMMProfile]>!
    fileprivate var inboxObserver: AnyObserver<[LMMProfile]>?
    
    fileprivate var sentObservable: Observable<[LMMProfile]>!
    fileprivate var sentObserver: AnyObserver<[LMMProfile]>?
    
    fileprivate var userPhotosObservable: Observable<[UserPhoto]>!
    fileprivate var userPhotosObserver: AnyObserver<[UserPhoto]>?
    
    fileprivate var userProfileObservable: Observable<UserProfile?>!
    fileprivate var userProfileObserver: AnyObserver<UserProfile?>?
    
    init()
    {
        let version: UInt64 = 12
        let config = Realm.Configuration(schemaVersion: version, migrationBlock: { (migration, oldVersion) in
            if oldVersion < 4 {
                migration.enumerateObjects(ofType: Photo.className(), { (_, newObject) in
                    newObject?["thumbnailPath"] = ""
                    newObject?["thumbnailPathType"] = 0
                })
            }
            
            if oldVersion < 5 {
                migration.enumerateObjects(ofType: NewFaceProfile.className(), { (_, newObject) in
                    newObject?["status"] = 0
                    newObject?["statusText"] = ""
                    newObject?["distanceText"] = ""
                })
                
                migration.enumerateObjects(ofType: LMMProfile.className(), { (_, newObject) in
                    newObject?["status"] = 0
                    newObject?["statusText"] = ""
                    newObject?["distanceText"] = ""
                })
            }
            
            if oldVersion < 6 {
                migration.enumerateObjects(ofType: NewFaceProfile.className(), { (_, newObject) in
                    newObject?["age"] = 0
                })
                
                migration.enumerateObjects(ofType: LMMProfile.className(), { (_, newObject) in
                    newObject?["age"] = 0
                })
            }
            
            if oldVersion < 7 {
                migration.enumerateObjects(ofType: LMMProfile.className(), { (_, newObject) in
                    newObject?["notRead"] = false
                })
                
                migration.enumerateObjects(ofType: Message.className(), { (_, newObject) in
                    newObject?["id"] = UUID().uuidString
                    newObject?["timestamp"] = Date()
                })
            }
            
            if oldVersion < 8 {
                migration.enumerateObjects(ofType: Profile.className(), { (_, newObject) in
                    newObject?["property"] = RealmOptional<Int>()
                    newObject?["transport"] = RealmOptional<Int>()
                    newObject?["income"] = RealmOptional<Int>()
                    newObject?["height"] = RealmOptional<Int>()
                    newObject?["educationLevel"] = RealmOptional<Int>()
                    newObject?["hairColor"] = RealmOptional<Int>()
                    newObject?["children"] = RealmOptional<Int>()
                    
                    newObject?["name"] = nil
                    newObject?["jobTitle"] = nil
                    newObject?["company"] = nil
                    newObject?["education"] = nil
                    newObject?["about"] = nil
                    newObject?["instagram"] = nil
                    newObject?["tikTok"] = nil
                    newObject?["whereLive"] = nil
                    newObject?["whereFrom"] = nil
                })
            }
            
            if oldVersion < 9 {
                migration.enumerateObjects(ofType: Profile.className(), { (_, newObject) in
                    newObject?["gender"] = nil
                })
            }
            
            if oldVersion < 10 {
                migration.enumerateObjects(ofType: Profile.className(), { (_, newObject) in
                    newObject?["statusInfo"] = nil
                })
            }
            
            if oldVersion < 11 {
                migration.enumerateObjects(ofType: Profile.className(), { (_, newObject) in
                    newObject?["totalLikes"] = 0
                })
            }
            
            if oldVersion < 12 {
                migration.enumerateObjects(ofType: Message.className(), { (_, newObject) in
                    newObject?["isRead"] = true
                    newObject?["msgId"] = ""
                })
            }
        }, deleteRealmIfMigrationNeeded: false)
        
        self.realm = try! Realm(configuration: config)
        self.currentOrderPosition = UserDefaults.standard.integer(forKey: "db_service_order_position_key")
        self.cleanDeletedObjects()
        self.setupObservers()
    }
    
    // MARK: - User Profile
    func userProfile() -> Observable<UserProfile?>
    {
        return self.userProfileObservable
    }
    
    func isBlocked(_ profileId: String) -> Bool
    {
        return self.realm.objects(BlockedProfile.self).map({ $0.id }).contains(profileId)
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
    
    func messages() -> Observable<[LMMProfile]>
    {
        return self.messagesObservable
    }
    
    func inbox() -> Observable<[LMMProfile]>
    {
        return self.inboxObservable
    }
    
    func sent() -> Observable<[LMMProfile]>
    {
        return self.sentObservable
    }
    
    func lmmDuplicates(_ id: String) -> Single<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "id = %@ AND isDeleted = false", id)
        
        return .just(Array(self.realm.objects(LMMProfile.self).filter(predicate)))
    }
    
    func blockProfile(_ id: String)
    {
        let blockedProfile = BlockedProfile()
        blockedProfile.id = id
        self.add(blockedProfile).subscribe(onSuccess: { [weak self] _ in
            self?.removeProfiles(id)
        }).disposed(by: self.disposeBag)
    }
    
    func updateSeen(_ id: String, isSeen: Bool)
    {
        let predicate = NSPredicate(format: "id = %@ AND isDeleted = false", id)
        guard let lmmProfile = self.realm.objects(LMMProfile.self).filter(predicate).first else { return }
        guard lmmProfile.notSeen != !isSeen else { return }
        
        if self.realm.isInWriteTransaction {
            lmmProfile.notSeen = !isSeen
            self.checkObjectsForUpdates([lmmProfile])
        } else {
            try? self.realm.write {
                lmmProfile.notSeen = !isSeen
                self.checkObjectsForUpdates([lmmProfile])
            }
        }
    }
        
    func forceMark(_ profile: LMMProfile, isSeen: Bool)
    {
        if self.realm.isInWriteTransaction {
            profile.notSeen = !isSeen
            self.checkObjectsForUpdates([profile])
        } else {
            try? self.realm.write {
                profile.notSeen = !isSeen
                self.checkObjectsForUpdates([profile])
            }
        }
    }
    
    
    func forceUpdateLMM()
    {
        self.updateLikesYou()
        self.updateMessages()
    }
    
    func forceUpdateMessages()
    {
        self.updateInbox()
        self.updateSent()
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
    
    // MARK: - Feeds
    
    func lmmProfileUpdate(_ id: String, messages: [Message], status: OnlineStatus, statusText: String, distanceText: String, totalLikes: Int)
    {
        let predicate = NSPredicate(format: "isDeleted = false AND id = %@", id)
        if  let profile = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition").first {
            self.write {
                profile.status = status.rawValue
                profile.statusText = statusText
                profile.distanceText = distanceText
                profile.totalLikes = totalLikes
                
                var notSentMessages: [Message] = []
                let remoteMessagesIds: [String] = messages.map({ $0.id })
                
                profile.messages.forEach({ localMessage in
                    if  localMessage.msgId == "" && !remoteMessagesIds.contains(localMessage.id) {
                        notSentMessages.append(localMessage)
                    }
                })
                
                var mergedMessages: [Message] = []
                mergedMessages.append(contentsOf: messages)
                mergedMessages.append(contentsOf: notSentMessages)
                
                profile.messages.removeAll()
                profile.messages.append(objectsIn: mergedMessages)
                self.updateOrder(Array(profile.messages), silently: true)

                self.checkObjectsForUpdates([profile])
            }
        }
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
    
    func updateOrder(_ object: DBServiceObject, silently: Bool)
    {
        self.updateOrder([object], silently: silently)
    }
    
    func updateOrder(_ objects: [DBServiceObject], silently: Bool)
    {
        if self.realm.isInWriteTransaction {
            objects.forEach { object in
                object.orderPosition = self.currentOrderPosition
                self.currentOrderPosition += 1
            }
 
            if !silently {
                self.checkObjectsForUpdates(objects)
            }
        } else {
            try? self.realm.write {
                objects.forEach { object in
                    object.orderPosition = self.currentOrderPosition
                    self.currentOrderPosition += 1
                }
                
                if !silently {
                    self.checkObjectsForUpdates(objects)
                }
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
    
    func write(_ block: (() -> ())? )
    {
        if self.realm.isInWriteTransaction {
            block?()
        } else {
            try? self.realm.write {
                block?()
            }
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
        
        guard profiles.count != 0 else { return .just(()) }
        
        return self.delete(Array(profiles))
    }
    
    func reset()
    {
        self.newFacesObserver?.onNext([])
        self.likesYouObserver?.onNext([])        
        self.messagesObserver?.onNext([])
        self.inboxObserver?.onNext([])
        self.sentObserver?.onNext([])
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
        }).share()
        
        self.likesYouObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.likesYouObserver = observer
            self?.updateLikesYou()
            
            return Disposables.create()
        }).share()
        
        
        self.messagesObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.messagesObserver = observer
            self?.updateMessages()
            
            return Disposables.create()
        }).share()
        
        self.inboxObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.inboxObserver = observer
            self?.updateInbox()
            
            return Disposables.create()
        }).share()
        
        self.sentObservable = Observable<[LMMProfile]>.create({ [weak self] observer -> Disposable in
            self?.sentObserver = observer
            self?.updateSent()
            
            return Disposables.create()
        }).share()
        
        self.userPhotosObservable = Observable<[UserPhoto]>.create({ [weak self] observer -> Disposable in
            self?.userPhotosObserver = observer
            self?.updateUserPhotos()
            
            return Disposables.create()
        }).share()
        
        self.userProfileObservable = Observable<UserProfile?>.create({ [weak self] observer -> Disposable in
            self?.userProfileObserver = observer
            self?.updateUserProfile()
            
            return Disposables.create()
            }).share()
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
    
    fileprivate func updateMessages()
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.messages.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.messagesObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateInbox()
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.inbox.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.inboxObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateSent()
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.sent.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.sentObserver?.onNext(profiles.toArray())
    }
    
    fileprivate func updateUserPhotos()
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let photos = self.realm.objects(UserPhoto.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        self.userPhotosObserver?.onNext(photos.toArray())
    }
    
    fileprivate func updateUserProfile()
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let profile = self.realm.objects(UserProfile.self).filter(predicate).first
        
        self.userProfileObserver?.onNext(profile)
    }
    
    func checkObjectsForUpdates(_ objects: [DBServiceObject])
    {
        var shouldUpdateNewFaces: Bool = false
        var shouldUpdateLikesYou: Bool = false
        var shouldUpdateMessages: Bool = false
        var shouldUpdateInbox: Bool = false
        var shouldUpdateSent: Bool = false        
        var shouldUpdateUserPhotos: Bool = false
        var shouldUpdateUserProfile: Bool = false
        
        objects.forEach { object in
            if let _ = object as? NewFaceProfile { shouldUpdateNewFaces = true }
            if let _ = object as? UserPhoto { shouldUpdateUserPhotos = true }
            if let _ = object as? UserProfile { shouldUpdateUserProfile = true }
            
            if let profile = object as? LMMProfile {
                if profile.type == FeedType.likesYou.rawValue { shouldUpdateLikesYou = true }                
                if profile.type == FeedType.messages.rawValue { shouldUpdateMessages = true }
                if profile.type == FeedType.inbox.rawValue { shouldUpdateInbox = true }
                if profile.type == FeedType.sent.rawValue { shouldUpdateSent = true }
            }
        }
        
        if shouldUpdateNewFaces { self.updateNewFaces() }
        if shouldUpdateLikesYou { self.updateLikesYou() }
        if shouldUpdateMessages { self.updateMessages() }
        if shouldUpdateInbox { self.updateInbox() }
        if shouldUpdateSent { self.updateSent() }
        if shouldUpdateUserPhotos { self.updateUserPhotos() }
        if shouldUpdateUserProfile { self.updateUserProfile() }
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
        objectsToDelete.append(contentsOf: Array(self.realm.objects(UserProfile.self).filter(predicate)))

        try? self.realm.write {
            self.realm.delete(objectsToDelete)
        }
    }
}
