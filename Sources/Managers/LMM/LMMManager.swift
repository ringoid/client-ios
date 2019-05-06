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
    let storage: XStorageService
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    var likesYou: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var matches: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var hellos: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var inbox: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var sent: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    
    let isFetching: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate var likesYouCached: [LMMProfile] = []
    fileprivate var matchesCached: [LMMProfile] = []
    fileprivate var hellosCached: [LMMProfile] = []
    fileprivate var inboxCached: [LMMProfile] = []
    fileprivate var sentCached: [LMMProfile] = []
    var contentShouldBeHidden: Bool = false
    {
        didSet {
            guard oldValue != self.contentShouldBeHidden else { return }
            
            if self.contentShouldBeHidden {
                self.likesYou.accept([])
                self.matches.accept([])
                self.hellos.accept([])
                self.inbox.accept([])
                self.sent.accept([])
            } else {
                self.likesYou.accept(self.likesYouCached)
                self.matches.accept(self.matchesCached)
                self.hellos.accept(self.hellosCached)
                self.inbox.accept(self.inboxCached)
                self.sent.accept(self.sentCached)
            }
        }
    }
    
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
    
    var notSeenHellosCount: Observable<Int>
    {
        return self.hellos.asObservable().map { profiles -> Int in
            var notSeenCount: Int = 0
            profiles.forEach({ profile in
                guard !profile.isInvalidated else { return }
                if profile.notSeen { notSeenCount += 1 }
            })
            
            return notSeenCount
        }
    }
    
    var notSeenInboxCount: Observable<Int>
    {
        return self.inbox.asObservable().map { profiles -> Int in
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
    
    fileprivate var prevNotSeenHellos: [String] = []
    var incomingMessages: Observable<Int>
    {
        return self.hellos.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen })
            
            return notSeenProfiles.filter({ !self.prevNotSeenHellos.contains($0.id) }).count
        }
    }
    
    fileprivate var prevNotSeenInbox: [String] = []
    var incomingInbox: Observable<Int>
    {
        return self.inbox.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen })
            
            return notSeenProfiles.filter({ !self.prevNotSeenInbox.contains($0.id) }).count
        }
    }
    
    init(_ db: DBService, api: ApiService, device: DeviceService, actionsManager: ActionsManager, storage: XStorageService)
    {
        self.db = db
        self.apiService = api
        self.deviceService = device
        self.actionsManager = actionsManager
        self.storage = storage
        
        self.setupBindings()
        self.loadPrevState()
    }
    
    fileprivate func refresh(_ from: SourceFeedType) -> Observable<Void>
    {
        log("LMM reloading process started", level: .high)
        self.isFetching.accept(true)
        let chatCache = (
            self.hellos.value +
            self.likesYou.value +
            self.matches.value +
            self.inbox.value +
            self.sent.value
        ).map({ ChatProfileCache.create($0) })
        
        self.updateProfilesPrevState(false)
        
        return self.apiService.getLMHIS(self.deviceService.photoResolution, lastActionDate: self.actionsManager.lastActionDate.value,source: from).flatMap({ [weak self] result -> Observable<Void> in
            
            self!.purge()
            
            let localLikesYou = createProfiles(result.likesYou, type: .likesYou)
            let matches = createProfiles(result.matches, type: .matches)
            let hellos = createProfiles(result.hellos, type: .hellos)
            let inbox = createProfiles(result.inbox, type: .inbox)
            let sent = createProfiles(result.sent, type: .sent)
            
            (hellos + matches + localLikesYou + inbox + sent).forEach { remoteProfile in
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
            
            return self!.db.add(localLikesYou + matches + hellos + inbox + sent).asObservable().do(onNext: { [weak self] _ in
                self?.updateProfilesPrevState(true)
            })
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
        // let startDate = Date()
        
        return self.actionsManager.sendQueue().flatMap ({ [weak self] _ -> Observable<Void> in
            
            return self!.refresh(from).asObservable()
        }).do(onNext: { _ in
//            if Date().timeIntervalSince(startDate) < 2.0 {
//                SentryService.shared.send(.waitingForResponseLLM)
//            }
        })
    }
    
    func purge()
    {
        self.db.resetLMM().subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func setupBindings()
    {
        self.db.likesYou().subscribe(onNext: { [weak self] profiles in
            self?.likesYouCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.likesYou.accept(profiles)
        }).disposed(by: self.disposeBag)

        self.db.matches().subscribe(onNext: { [weak self] profiles in
            self?.matchesCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.matches.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.db.hellos().subscribe(onNext: { [weak self] profiles in
            self?.hellosCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.hellos.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.db.inbox().subscribe(onNext: { [weak self] profiles in
            self?.inboxCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.inbox.accept(profiles)
        }).disposed(by: self.disposeBag)
        
        self.db.sent().subscribe(onNext: { [weak self] profiles in
            self?.sentCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.sent.accept(profiles)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func loadPrevState()
    {
        self.storage.object("prevNotSeenLikes").subscribe( onSuccess: { obj in
            self.prevNotSeenLikes = Array<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("prevNotSeenMatches").subscribe( onSuccess: { obj in
            self.prevNotSeenMatches = Array<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("prevNotSeenHellos").subscribe( onSuccess: { obj in
            self.prevNotSeenHellos = Array<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("prevNotSeenInbox").subscribe( onSuccess: { obj in
            self.prevNotSeenInbox = Array<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateProfilesPrevState(_ avoidEmptyFeeds: Bool)
    {
        let notSeenLikes = self.likesYou.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenLikes.count > 0 || !avoidEmptyFeeds { self.prevNotSeenLikes = notSeenLikes }
        
        let notSeenMatches = self.matches.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenMatches.count > 0 || !avoidEmptyFeeds { self.prevNotSeenMatches = notSeenMatches }
        
        let notSeenHellos = self.hellos.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenHellos.count > 0 || !avoidEmptyFeeds { self.prevNotSeenHellos = notSeenHellos }
        
        let notSeenInbox = self.inbox.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenInbox.count > 0 || !avoidEmptyFeeds { self.prevNotSeenInbox = notSeenInbox }
        
        self.storage.store(self.prevNotSeenLikes, key: "prevNotSeenLikes").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenMatches, key: "prevNotSeenMatches").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenHellos, key: "prevNotSeenHellos").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenInbox, key: "prevNotSeenInbox").subscribe().disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.storage.remove("prevNotSeenLikes").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenMatches").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenHellos").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenInbox").subscribe().disposed(by: self.disposeBag)
        
        self.likesYouCached.removeAll()
        self.matchesCached.removeAll()
        self.hellosCached.removeAll()
        self.inboxCached.removeAll()
        self.sentCached.removeAll()
        
        self.prevNotSeenLikes.removeAll()
        self.prevNotSeenMatches.removeAll()
        self.prevNotSeenHellos.removeAll()
        self.prevNotSeenInbox.removeAll()
        
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

