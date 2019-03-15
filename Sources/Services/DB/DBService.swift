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
    
    init()
    {
        let version: UInt64 = 3
        let config = Realm.Configuration(schemaVersion: version, deleteRealmIfMigrationNeeded: true)
        
        self.realm = try! Realm(configuration: config)
        self.currentOrderPosition = UserDefaults.standard.integer(forKey: "db_service_order_position_key")
        self.cleanDeletedObjects()
    }
    
    // MARK: - New Faces
    func fetchNewFaces() -> Observable<[NewFaceProfile]>
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let profiles = self.realm.objects(NewFaceProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        return Observable.array(from: profiles)
    }

    // MARK: - LMM
    
    func fetchLikesYou() -> Observable<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.likesYou.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        return Observable.array(from: profiles)
    }
    
    func fetchMatches() -> Observable<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.matches.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        return Observable.array(from: profiles)
    }
    
    func fetchMessages() -> Observable<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "type = %d AND isDeleted = false", FeedType.messages.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        return Observable.array(from: profiles)
    }
    
    func blockProfile(_ id: String)
    {
        let blockedProfile = BlockedProfile()
        blockedProfile.id = id
        self.add(blockedProfile).subscribe(onNext: { [weak self] _ in
            self?.removeProfiles(id)
        }).disposed(by: self.disposeBag)
    }

    // MARK: - User
    
    func fetchUserPhotos() -> Observable<[UserPhoto]>
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let photos = self.realm.objects(UserPhoto.self).filter(predicate).sorted(byKeyPath: "orderPosition")
        
        return Observable.array(from: photos)
    }
    
    func fetchUserPhoto(_ clientId: String) -> Observable<UserPhoto?>
    {
        let predicate = NSPredicate(format: "clientId = %@ AND isDeleted = false", clientId)
        let photo = self.realm.objects(UserPhoto.self).filter(predicate).first
        
        return .just(photo)
    }
    
    // MARK: - Actions
    
    func fetchActions() -> Observable<[Action]>
    {
        let predicate = NSPredicate(format: "isDeleted = false")
        let actions = self.realm.objects(Action.self).filter(predicate)
        
        return Observable.array(from: actions)
    }
    
    // MARK: - Common
    
    func add(_ object: DBServiceObject) -> Observable<Void>
    {
        return self.add([object])
    }
    
    func add(_ objects: [DBServiceObject]) -> Observable<Void>
    {
        objects.forEach { object in
            object.orderPosition = self.currentOrderPosition
            self.currentOrderPosition += 1
        }
        
        UserDefaults.standard.set(self.currentOrderPosition, forKey: "db_service_order_position_key")
        UserDefaults.standard.synchronize()
        
        let objectsToAdd = self.filterBlocked(objects)

        return Observable<Void>.create({ observer -> Disposable in                       
            if self.realm.isInWriteTransaction {
                self.realm.add(objectsToAdd)
                observer.onNext(())
                observer.onCompleted()
            } else {
                try? self.realm.write {
                    self.realm.add(objectsToAdd)
                    observer.onNext(())
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        })
    }
    
    func updateOrder(_ object: DBServiceObject)
    {
        if self.realm.isInWriteTransaction {
            object.orderPosition = self.currentOrderPosition
            self.currentOrderPosition += 1
        } else {
            try? self.realm.write {
                object.orderPosition = self.currentOrderPosition
                self.currentOrderPosition += 1
            }
        }
    }
    
    func delete(_ objects: [DBServiceObject]) -> Observable<Void>
    {
        return Observable<Void>.create({ [weak self] observer -> Disposable in
            guard let `self` = self else { return Disposables.create() }
            
            if self.realm.isInWriteTransaction {
                objects.forEach({ $0.isDeleted = true })
                observer.onNext(())
                observer.onCompleted()
            } else {
                try? self.realm.write {
                    objects.forEach({ $0.isDeleted = true })
                    observer.onNext(())
                    observer.onCompleted()
                }
            }

            return Disposables.create()
        })
    }
    
    // MARK: - Resets
    
    func resetLMM() -> Observable<Void>
    {
        let profiles = self.realm.objects(LMMProfile.self)
        return self.delete(Array(profiles))
    }
    
    func resetNewFaces() -> Observable<Void>
    {
        let profiles = self.realm.objects(NewFaceProfile.self)
        return self.delete(Array(profiles))
    }
    
    func reset()
    {
        try? self.realm.write {
            self.realm.deleteAll()
        }
        
        self.currentOrderPosition = 0
        UserDefaults.standard.removeObject(forKey: "db_service_order_position_key")
        UserDefaults.standard.synchronize()
    }
    
    // MARK: -
    fileprivate func removeProfiles(_ id: String)
    {
        var objectsToRemove: [Object] = []
        let predicate = NSPredicate(format: "id = %@ AND isDeleted = false", id)
        objectsToRemove.append(contentsOf: Array(self.realm.objects(NewFaceProfile.self).filter(predicate)))
        objectsToRemove.append(contentsOf: Array(self.realm.objects(LMMProfile.self).filter(predicate)))
        self.realm.delete(objectsToRemove)        
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
