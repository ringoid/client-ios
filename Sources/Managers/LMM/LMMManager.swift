//
//  LMMManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

class LMMManager
{
    let db: DBService
    let apiService: ApiService
    let actionsManager: ActionsManager
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    var likesYou: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var matches: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var messages: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    
    init(_ db: DBService, api: ApiService, actionsManager: ActionsManager)
    {
        self.db = db
        self.apiService = api
        self.actionsManager = actionsManager
        
        self.db.fetchLikesYou().bind(to: self.likesYou).disposed(by: self.disposeBag)
        self.db.fetchMatches().bind(to: self.matches).disposed(by: self.disposeBag)
        self.db.fetchMessages().bind(to: self.messages).disposed(by: self.disposeBag)
    }
    
    func refresh() -> Observable<Void>
    {
        return self.apiService.getLMM(.small, lastActionDate: self.actionsManager.lastActionDate).flatMap({ [weak self] result -> Observable<Void> in
            
            let localLikesYou = createProfiles(result.likesYou, type: .likesYou)
            let matches = createProfiles(result.matches, type: .matches)
            let messages = createProfiles(result.messages, type: .messages)
            
            return self!.db.add(localLikesYou + matches + messages)
        })       
    }
}

fileprivate func createProfiles(_ from: [ApiLMMProfile], type: FeedType) -> [LMMProfile]
{
    return from.map({ profile -> LMMProfile in
        let localPhotos = profile.photos.map({ photo -> Photo in
            let localPhoto = Photo()
            localPhoto.id = photo.id
            localPhoto.url = photo.url
            
            return localPhoto
        })
        
        let localMessages = profile.messages.map({ message -> Message in
            let localMessage = Message()
            localMessage.wasYouSender = message.wasYouSender
            localMessage.text = message.text
            
            return localMessage
        })
        
        let localProfile = LMMProfile()
        localProfile.type = type.rawValue
        localProfile.id = profile.id
        localProfile.notSeen = profile.notSeen
        localProfile.defaultSortingOrderPosition = profile.defaultSortingOrderPosition
        localProfile.photos.append(objectsIn: localPhotos)
        localProfile.messages.append(objectsIn: localMessages)
        
        return localProfile
    })
}

