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
    
    init()
    {
        self.realm = try! Realm(configuration: .defaultConfiguration)
    }
    
    // MARK: - New Faces
    func fetchNewFaces() -> Observable<[NewFaceProfile]>
    {
        let profiles = self.realm.objects(NewFaceProfile.self)
        
        return Observable.array(from: profiles)
    }

    // MARK: - LMM
    
    func fetchLikesYou() -> Observable<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "type = %d", FeedType.likesYou.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate)
        
        return Observable.array(from: profiles)
    }
    
    func fetchMatches() -> Observable<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "type = %d", FeedType.matches.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate)
        
        return Observable.array(from: profiles)
    }
    
    func fetchMessages() -> Observable<[LMMProfile]>
    {
        let predicate = NSPredicate(format: "type = %d", FeedType.messages.rawValue)
        let profiles = self.realm.objects(LMMProfile.self).filter(predicate)
        
        return Observable.array(from: profiles)
    }

    // MARK: - User
    
    func fetchUserPhotos() -> Observable<[UserPhoto]>
    {
        let photos = self.realm.objects(UserPhoto.self)
        
        return Observable.array(from: photos)
    }
//    
//    // MARK: - Photos
//    
//    func photo(_ id: String) -> Observable<Photo>
//    {
//        let predicate = NSPredicate(format: "id = %@", id)
//        guard let photo = self.realm.objects(Photo.self).filter(predicate).first else {
//            let error = createError("No new face profile found with id = \(id)", type: .hidden)
//            
//            return .error(error)
//        }
//        
//        return .just(photo)
//    }

    
    // MARK: - Actions
    
    func fetchActions() -> Observable<[Action]>
    {
        let actions = self.realm.objects(Action.self)
        
        return Observable.array(from: actions)
    }
    
    // MARK: - Common
    
    func add(_ object: Object) -> Observable<Void>
    {
        return Observable<Void>.create({ [weak self] observer -> Disposable in
            try? self?.realm.write {
                self?.realm.add(object)
                observer.onNext(())
                observer.onCompleted()
            }
            
            return Disposables.create()
        })
    }
    
    func add(_ objects: [Object]) -> Observable<Void>
    {
        return Observable<Void>.create({ [weak self] observer -> Disposable in
            try? self?.realm.write {
                self?.realm.add(objects)
                observer.onNext(())
                observer.onCompleted()
            }
            
            return Disposables.create()
        })
    }
    
    func delete(_ objects: [Object]) -> Observable<Void>
    {
        return Observable<Void>.create({ [weak self] observer -> Disposable in
            try? self?.realm.write {
                self?.realm.delete(objects)
                observer.onNext(())
                observer.onCompleted()
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
    }
}
