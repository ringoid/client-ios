//
//  LMMManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

fileprivate struct ChatProfileCache
{
    let id: String
    let messagesCount: Int
    let notSeen: Bool
    
    static func create(_ profile: LMMProfile) -> ChatProfileCache
    {
        return ChatProfileCache(
            id: profile.id,
            messagesCount: profile.messages.count,
            notSeen: profile.notSeen
        )
    }
}

class LMMManager
{
    let db: DBService
    let apiService: ApiService
    let actionsManager: ActionsManager
    let deviceService: DeviceService
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    var likesYou: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var matches: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var messages: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    
    let isFetching: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    // Not seen counters
    
    var notSeenLikesYouCount: Observable<Int>
    {
        return self.likesYou.asObservable().map { profiles -> Int in
            var notSeenCount: Int = 0
            profiles.forEach({ profile in
                if profile.notSeen { notSeenCount += 1 }
            })
            
            return notSeenCount
        }
    }
    
    var notSeenMatchesCount: Observable<Int>
    {
        return self.matches.asObservable().map { profiles -> Int in
            var notSeenCount: Int = 0
            profiles.forEach({ profile in
                if profile.notSeen { notSeenCount += 1 }
            })
            
            return notSeenCount
        }
    }
    
    var notSeenMessagesCount: Observable<Int>
    {
        return self.messages.asObservable().map { profiles -> Int in
            var notSeenCount: Int = 0
            profiles.forEach({ profile in
                guard !profile.isInvalidated else { return }
                if profile.notSeen { notSeenCount += 1 }
            })
            
            return notSeenCount
        }
    }
    
    // Incoming counters
    
    fileprivate var prevNotSeenLikes: [String] = []
    var incomingLikesYouCount: Observable<Int>
    {
        return self.likesYou.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen })

            return notSeenProfiles.filter({ !self.prevNotSeenLikes.contains($0.id) }).count
        }
    }
    
    fileprivate var prevNotSeenMatches: [String] = []
    var incomingMatches: Observable<Int>
    {
        return self.matches.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen })

            return notSeenProfiles.filter({ !self.prevNotSeenMatches.contains($0.id) }).count
        }
    }
    
    fileprivate var prevNotSeenMessages: [String] = []
    var incomingMessages: Observable<Int>
    {
        return self.messages.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen })
            
            return notSeenProfiles.filter({ !self.prevNotSeenMessages.contains($0.id) }).count
        }
    }
    
    init(_ db: DBService, api: ApiService, device: DeviceService, actionsManager: ActionsManager)
    {
        self.db = db
        self.apiService = api
        self.deviceService = device
        self.actionsManager = actionsManager
        
        self.setupBindings()
    }
    
    fileprivate func refresh(_ from: SourceFeedType) -> Observable<Void>
    {
        log("LMM reloading process started", level: .high)
        self.isFetching.accept(true)
        let chatCache = (
            self.messages.value +
            self.likesYou.value +
            self.matches.value
        ).map({ ChatProfileCache.create($0) })
        
        self.prevNotSeenLikes = self.likesYou.value.filter({ $0.notSeen }).map({ $0.id })
        self.prevNotSeenMatches = self.matches.value.filter({ $0.notSeen }).map({ $0.id })
        self.prevNotSeenMessages = self.messages.value.filter({ $0.notSeen }).map({ $0.id })
        
        return self.apiService.getLMM(self.deviceService.photoResolution, lastActionDate: self.actionsManager.lastActionDate.value,source: from).flatMap({ [weak self] result -> Observable<Void> in
            
            self!.purge()
            
            let localLikesYou = createProfiles(result.likesYou, type: .likesYou)
            let matches = createProfiles(result.matches, type: .matches)
            let messages = createProfiles(result.messages, type: .messages)
            
            (messages + matches + localLikesYou).forEach { remoteProfile in
                guard remoteProfile.messages.count != 0 else { return }
                remoteProfile.notSeen = true
                
                chatCache.forEach { localChatProfile in
                    if localChatProfile.id == remoteProfile.id {
                        if localChatProfile.messagesCount == remoteProfile.messages.count {
                            remoteProfile.notSeen = localChatProfile.notSeen
                        } else {
                            remoteProfile.notSeen = true
                        }
                    }
                }
            }
            
            return self!.db.add(localLikesYou + matches + messages).asObservable()
        }).asObservable().delay(0.05, scheduler: MainScheduler.instance).do(
            onNext: { [weak self] _ in
                self?.isFetching.accept(false)
        },
            onError: { [weak self] _ in
                self?.isFetching.accept(false)
        })
    }
    
    func refreshInBackground(_ from: SourceFeedType)
    {
        self.refreshProtected(from).subscribe().disposed(by: self.disposeBag)
    }
    
    func refreshProtected(_ from: SourceFeedType) -> Observable<Void>
    {
        let startDate = Date()
        
        return self.actionsManager.sendQueue().flatMap ({ [weak self] _ -> Observable<Void> in
            
            return self!.refresh(from).asObservable()
        }).do(onNext: { _ in
            if Date().timeIntervalSince(startDate) < 2.0 {
                SentryService.shared.send(.waitingForResponseLLM)
            }
        })
    }
    
    func purge()
    {
        self.db.resetLMM().subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBindings()
    {
        self.db.likesYou().subscribeOn(MainScheduler.instance).bind(to: self.likesYou).disposed(by: self.disposeBag)
        self.db.matches().subscribeOn(MainScheduler.instance).bind(to: self.matches).disposed(by: self.disposeBag)
        self.db.messages().subscribeOn(MainScheduler.instance).bind(to: self.messages).disposed(by: self.disposeBag)        
    }
    
    func reset()
    {
        self.disposeBag = DisposeBag()
        self.setupBindings()
    }
}

fileprivate func createProfiles(_ from: [ApiLMMProfile], type: FeedType) -> [LMMProfile]
{
    var localOrderPosition: Int = 0
    
    return from.map({ profile -> LMMProfile in
        let localPhotos = profile.photos.map({ photo -> Photo in
            let localPhoto = Photo()
            localPhoto.id = photo.id
            localPhoto.path = photo.url
            localPhoto.pathType = FileType.url.rawValue
            localPhoto.orderPosition = localOrderPosition
            localOrderPosition += 1
            
            return localPhoto
        })
        
        let localMessages = profile.messages.map({ message -> Message in
            let localMessage = Message()
            localMessage.wasYouSender = message.wasYouSender
            localMessage.text = message.text
            localMessage.orderPosition = localOrderPosition
            localOrderPosition += 1
            
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

