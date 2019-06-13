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
    let notifications: NotificationService
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    var likesYou: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var matches: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var messages: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var inbox: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var sent: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    
    let isFetching: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    fileprivate var likesYouCached: [LMMProfile] = []
    fileprivate var matchesCached: [LMMProfile] = []
    fileprivate var messagesCached: [LMMProfile] = []
    fileprivate var inboxCached: [LMMProfile] = []
    fileprivate var sentCached: [LMMProfile] = []
    
    fileprivate var likesYouNotificationProfiles: Set<String> = []
    fileprivate var matchesNotificationProfiles: Set<String> = []
    fileprivate var messagesNotificationProfiles: Set<String> = []
    fileprivate var processedNotificationsProfiles: Set<String> = []
    
    var contentShouldBeHidden: Bool = false
    {
        didSet {
            guard oldValue != self.contentShouldBeHidden else { return }
            
            if self.contentShouldBeHidden {
                self.likesYou.accept([])
                self.matches.accept([])
                self.messages.accept([])
                self.inbox.accept([])
                self.sent.accept([])
            } else {
                self.likesYou.accept(self.likesYouCached)
                self.matches.accept(self.matchesCached)
                self.messages.accept(self.messagesCached)
                self.inbox.accept(self.inboxCached)
                self.sent.accept(self.sentCached)
            }
        }
    }
    
    // Not seen counters
    
    let notSeenLikesYouCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let notSeenMatchesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let notSeenMessagesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)

    var notSeenInboxCount: Observable<Int>!
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
    
    let notSeenTotalCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let notificationsProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let lmmCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    // Incoming counters
    
    fileprivate var prevNotSeenLikes: [String] = []
    var incomingLikesYouCount: Observable<Int>
    {
        return self.likesYou.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen && $0.id != self.apiService.customerId.value })

            return notSeenProfiles.filter({ !self.prevNotSeenLikes.contains($0.id) }).count
        }
    }
    
    fileprivate var prevNotSeenMatches: [String] = []
    var incomingMatches: Observable<Int>
    {
        return self.matches.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen && $0.id != self.apiService.customerId.value })

            return notSeenProfiles.filter({ !self.prevNotSeenMatches.contains($0.id) }).count
        }
    }
    
    fileprivate var prevNotSeenMessages: [String] = []
    var incomingMessages: Observable<Int>
    {
        return self.messages.asObservable().map { profiles -> Int in
            let notSeenProfiles = profiles.filter({ $0.notSeen && $0.id != self.apiService.customerId.value })
            
            let updatedMessages = notSeenProfiles.filter({ !self.prevNotSeenMessages.contains($0.id) })
            
            return Set<String>(updatedMessages.map({ $0.id })).count
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
    
    fileprivate var notSeenLikesYouPrevCount: Int = 0
    fileprivate var notSeenMatchesPrevCount: Int = 0
    fileprivate var notSeenMessagesPrevCount: Int = 0
    
    // Updates
    
    fileprivate var prevLikesYouUpdatedProfiles: Set<String> = []
    fileprivate var prevMatchesUpdatedProfiles: Set<String> = []
    fileprivate var prevMessagesUpdatedProfiles: Set<String> = []
    
    var likesYouUpdatesAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var matchesUpdatesAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    var messagesUpdatesAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    init(_ db: DBService, api: ApiService, device: DeviceService, actionsManager: ActionsManager, storage: XStorageService, notifications: NotificationService)
    {
        self.db = db
        self.apiService = api
        self.deviceService = device
        self.actionsManager = actionsManager
        self.storage = storage
        self.notifications = notifications
        
        self.loadPrevState()
        self.setupBindings()
    }
    
    fileprivate func refresh(_ from: SourceFeedType) -> Observable<Void>
    {
        log("LMM reloading process started", level: .high)
        self.isFetching.accept(true)
        let chatCache = (
            self.messages.value +
            self.likesYou.value +
            self.matches.value +
            self.inbox.value +
            self.sent.value
        ).map({ ChatProfileCache.create($0) })
        
        self.updateProfilesPrevState(false)
        
        return self.apiService.getLMM(self.deviceService.photoResolution, lastActionDate: self.actionsManager.lastActionDate.value,source: from).flatMap({ [weak self] result -> Observable<Void> in
            
            self!.resetNotificationProfiles()
            self!.purge()
            
            let localLikesYou = createProfiles(result.likesYou, type: .likesYou)
            let matches = createProfiles(result.matches, type: .matches)
            let messages = createProfiles(result.messages, type: .messages)
            let inbox = createProfiles(result.inbox, type: .inbox)
            let sent = createProfiles(result.sent, type: .sent)
            
            (matches + messages).forEach { remoteProfile in
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
            
            return self!.db.add(localLikesYou + matches + messages + inbox + sent).asObservable().do(onNext: { [weak self] _ in
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
    
    func topOrder(_ profileId: String, type: LMMType)
    {
        switch type {
        case .inbox: self.db.updateOrder(self.inbox.value.filter({ $0.id != profileId }))
        case .sent: self.db.updateOrder(self.sent.value.filter({ $0.id != profileId }))
            
            
        default: return
        }
    }
    
    func updateChat(_ profileId: String)
    {
        self.actionsManager.sendQueue().subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.apiService.getChat(profileId,
                                    resolution: self.deviceService.photoResolution,
                                    lastActionDate: self.actionsManager.lastActionDate.value).subscribe(onNext: { [weak self] chatUpdate in
                                        
                                        self?.updateLocalProfile(profileId, update: chatUpdate)
                                        
                                        guard chatUpdate.pullAgainAfter > 0 else { return }
                                        
                                        let interval = Double(chatUpdate.pullAgainAfter) / 1000.0
                                        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: { [weak self] in
                                            self?.updateChat(profileId)
                                        })
                                    }).disposed(by: self.disposeBag)
            
        }).disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.storage.remove("prevNotSeenLikes").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenMatches").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenHellos").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenInbox").subscribe().disposed(by: self.disposeBag)
        
        self.likesYouCached.removeAll()
        self.matchesCached.removeAll()
        self.messagesCached.removeAll()
        self.inboxCached.removeAll()
        self.sentCached.removeAll()
        
        self.prevNotSeenLikes.removeAll()
        self.prevNotSeenMatches.removeAll()
        self.prevNotSeenMessages.removeAll()
        self.prevNotSeenInbox.removeAll()
        
        self.likesYou.accept([])
        self.matches.accept([])
        self.messages.accept([])
        self.inbox.accept([])
        self.sent.accept([])
        
        self.resetNotificationProfiles()
        
        self.disposeBag = DisposeBag()
        self.setupBindings()
    }
    
    // MARK: - Notifications
    func isMessageNotificationAlreadyProcessed(_ profileId: String) -> Bool
    {
        return self.processedNotificationsProfiles.contains(profileId)
    }
    
    func markNotificationAsProcessed(_ profileId: String)
    {
        self.processedNotificationsProfiles.insert(profileId)
    }
    
    func removeNotificationFromProcessed(_ profileId: String)
    {
        self.processedNotificationsProfiles.remove(profileId)
    }
    
    // MARK: -
    
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
        
        self.db.messages().subscribe(onNext: { [weak self] profiles in
            self?.messagesCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.messages.accept(profiles)
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

        self.likesYou.asObservable().subscribe(onNext:{ [weak self] profiles in
            guard let `self` = self else { return }
            
            self.notSeenLikesYouCount.accept(profiles.notSeenCount + self.likesYouNotificationProfiles.count)
            self.updateLmmCount()
        }).disposed(by: self.disposeBag)
        
        self.matches.asObservable().subscribe(onNext:{ [weak self] profiles in
            guard let `self` = self else { return }
            
            self.notSeenMatchesCount.accept(profiles.notSeenCount + self.matchesNotificationProfiles.count)
            self.updateLmmCount()
        }).disposed(by: self.disposeBag)

        self.messages.asObservable().subscribe(onNext:{ [weak self] profiles in
            guard let `self` = self else { return }
            
            var notSeenLocalSet =  Set<String>(profiles.filter({ $0.notSeen }).map({ $0.id }))
            notSeenLocalSet = notSeenLocalSet.union(self.messagesNotificationProfiles)
            
            self.notSeenMessagesCount.accept(notSeenLocalSet.count)
            self.updateLmmCount()
        }).disposed(by: self.disposeBag)
        
        self.notifications.notificationData.subscribe(onNext: { [weak self] userInfo in
            guard let `self` = self else { return }
            guard let typeStr = userInfo["type"] as? String else { return }
            guard let remoteFeedType = RemoteFeedType(rawValue: typeStr) else { return }
            guard let profileId = userInfo["oppositeUserId"] as? String else { return }
            
            switch remoteFeedType {
            case .likesYou:
                self.likesYouNotificationProfiles.insert(profileId)
                let notSeenCount = self.likesYou.value.notSeenCount + self.likesYouNotificationProfiles.count
                self.notSeenLikesYouCount.accept(notSeenCount)
                
                break
                
            case .matches:
                self.likesYouNotificationProfiles.remove(profileId)
                self.matchesNotificationProfiles.insert(profileId)
                let notSeenCount = self.matches.value.notSeenCount + self.matchesNotificationProfiles.count
                self.notSeenMatchesCount.accept(notSeenCount)
                break
                
            case .messages:
                self.updateChat(profileId)
                
                if self.isMessageNotificationAlreadyProcessed(profileId) { break }
                if self.messagesNotificationProfiles.contains(profileId) { break }
                
                self.db.updateSeen(profileId, isSeen: false)
                
                if self.actionsManager.lmmViewingProfiles.value.contains(profileId) { break }
                
                self.likesYouNotificationProfiles.remove(profileId)
                self.matchesNotificationProfiles.remove(profileId)
                self.messagesNotificationProfiles.insert(profileId)
                
                var notSeenLocalSet =  Set<String>(self.messages.value.filter({ $0.notSeen }).map({ $0.id }))
                notSeenLocalSet = notSeenLocalSet.union(self.messagesNotificationProfiles)
                self.notSeenMessagesCount.accept(notSeenLocalSet.count)
                
                break
                
            case .unknown: break
            }
            
            let notificationsCount = self.likesYouNotificationProfiles.count +
                self.matchesNotificationProfiles.count +
                self.messagesNotificationProfiles.count
            self.notificationsProfilesCount.accept(notificationsCount)
            
            self.updateLmmCount()
            self.updateAvailability()
        }).disposed(by: self.disposeBag)
        
        // Total count
        
        self.notSeenLikesYouCount.subscribe(onNext: { [weak self] value in
            guard let `self` = self else { return }
            
            self.notSeenLikesYouPrevCount = value
            
            let totalCount = self.notSeenMatchesPrevCount +
                self.notSeenLikesYouPrevCount +
                self.notSeenMessagesPrevCount
            self.notSeenTotalCount.accept(totalCount)
        }).disposed(by: self.disposeBag)
        
        self.notSeenMatchesCount.subscribe(onNext: { [weak self] value in
            guard let `self` = self else { return }
            
            self.notSeenMatchesPrevCount = value
            
            let totalCount = self.notSeenMatchesPrevCount +
                self.notSeenLikesYouPrevCount +
                self.notSeenMessagesPrevCount
            self.notSeenTotalCount.accept(totalCount)
        }).disposed(by: self.disposeBag)
        
        self.notSeenMessagesCount.subscribe(onNext: { [weak self] value in
            guard let `self` = self else { return }
            
            self.notSeenMessagesPrevCount = value
            
            let totalCount = self.notSeenMatchesPrevCount +
                self.notSeenLikesYouPrevCount +
                self.notSeenMessagesPrevCount
            self.notSeenTotalCount.accept(totalCount)
        }).disposed(by: self.disposeBag)
        
        // Actions
        
        self.actionsManager.lmmViewingProfiles.subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            self.likesYouNotificationProfiles.subtract(profiles)
            self.matchesNotificationProfiles.subtract(profiles)
            self.messagesNotificationProfiles.subtract(profiles)
            
            self.notSeenLikesYouCount.accept(self.likesYou.value.notSeenCount + self.likesYouNotificationProfiles.count)
            self.notSeenMatchesCount.accept(self.matches.value.notSeenCount + self.matchesNotificationProfiles.count)
            
            var notSeenLocalSet =  Set<String>(self.messages.value.filter({ $0.notSeen }).map({ $0.id }))
            notSeenLocalSet = notSeenLocalSet.union(self.messagesNotificationProfiles)
            self.notSeenMessagesCount.accept(notSeenLocalSet.count)
            
            self.updateAvailability()
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
        
        self.storage.object("prevNotSeenMessages").subscribe( onSuccess: { obj in
            self.prevNotSeenMessages = Array<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("prevNotSeenInbox").subscribe( onSuccess: { obj in
            self.prevNotSeenInbox = Array<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateLocalProfile(_ id: String, update: ApiChatUpdate)
    {
        var localOrderPosition: Int = 0
        let updatedMessages = update.messages.map({ message -> Message in
            let localMessage = Message()
            localMessage.wasYouSender = message.wasYouSender
            localMessage.text = message.text
            localMessage.orderPosition = localOrderPosition
            localOrderPosition += 1
            
            return localMessage
        })
        
        self.db.lmmProfileUpdate(id,
                                 messages: updatedMessages,
                                 notSentMessagesCount: self.actionsManager.notCommitedMessagesCount,
                                 status: update.status?.onlineStatus() ?? .unknown,
                                 statusText: update.lastOnlineText ?? "unknown",
                                 distanceText: update.distanceText ?? "unknown"
        )
    }
    
    fileprivate func updateProfilesPrevState(_ avoidEmptyFeeds: Bool)
    {
        let notSeenLikes = self.likesYou.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenLikes.count > 0 || !avoidEmptyFeeds { self.prevNotSeenLikes = notSeenLikes }
        
        let notSeenMatches = self.matches.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenMatches.count > 0 || !avoidEmptyFeeds { self.prevNotSeenMatches = notSeenMatches }
        
        let notSeenMessages = self.messages.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenMessages.count > 0 || !avoidEmptyFeeds { self.prevNotSeenMessages = notSeenMessages }
        
        let notSeenInbox = self.inbox.value.filter({ $0.notSeen }).compactMap({ $0.id })
        if notSeenInbox.count > 0 || !avoidEmptyFeeds { self.prevNotSeenInbox = notSeenInbox }
        
        self.storage.store(self.prevNotSeenLikes, key: "prevNotSeenLikes").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenMatches, key: "prevNotSeenMatches").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenMessages, key: "prevNotSeenMessages").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenInbox, key: "prevNotSeenInbox").subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func updateLmmCount()
    {
        var lmmProfiles = Set((self.likesYou.value + self.matches.value + self.messages.value).map({ $0.id }))
        lmmProfiles = lmmProfiles.union(self.likesYouNotificationProfiles)
        lmmProfiles = lmmProfiles.union(self.matchesNotificationProfiles)
        lmmProfiles = lmmProfiles.union(self.messagesNotificationProfiles)
        
        self.lmmCount.accept(lmmProfiles.count)
    }
    
    fileprivate func updateAvailability()
    {
        // Likes you
        let updatedLikesYouProfiles = self.likesYouNotificationProfiles.subtracting(self.prevLikesYouUpdatedProfiles)
        self.prevLikesYouUpdatedProfiles = self.likesYouNotificationProfiles
        
        if updatedLikesYouProfiles.count > 0 { self.likesYouUpdatesAvailable.accept(true) }
        if self.likesYouNotificationProfiles.count == 0 { self.likesYouUpdatesAvailable.accept(false) }
        
        // Matches
        let updatedMatchesProfiles = self.matchesNotificationProfiles.subtracting(self.prevMatchesUpdatedProfiles)
        self.prevMatchesUpdatedProfiles = self.matchesNotificationProfiles
        
        if updatedMatchesProfiles.count > 0 { self.matchesUpdatesAvailable.accept(true) }
        if self.matchesNotificationProfiles.count == 0 { self.matchesUpdatesAvailable.accept(false) }

        // Messages
        let updatedMessagesProfiles = self.messagesNotificationProfiles.subtracting(self.prevMessagesUpdatedProfiles)
        self.prevMessagesUpdatedProfiles = self.messagesNotificationProfiles
        
        if updatedMessagesProfiles.count > 0 {
            // Single profile case
            if self.messages.value.count == 1, updatedMessagesProfiles.first == self.messages.value.first?.id { return }
            
            self.messagesUpdatesAvailable.accept(true)
        }
        
        if messagesNotificationProfiles.count == 0 { self.messagesUpdatesAvailable.accept(false) }
    }
    
    fileprivate func resetNotificationProfiles()
    {
        self.likesYouNotificationProfiles.removeAll()
        self.matchesNotificationProfiles.removeAll()
        self.messagesNotificationProfiles.removeAll()
        self.prevLikesYouUpdatedProfiles.removeAll()
        self.prevMatchesUpdatedProfiles.removeAll()
        self.prevMessagesUpdatedProfiles.removeAll()
        self.processedNotificationsProfiles.removeAll()
        self.notificationsProfilesCount.accept(0)
        self.lmmCount.accept(0)
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
            localPhoto.thumbnailPath = photo.thumbnailUrl
            localPhoto.thumbnailPathType = FileType.url.rawValue
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
        localProfile.age = profile.age
        localProfile.notSeen = profile.notSeen
        localProfile.defaultSortingOrderPosition = profile.defaultSortingOrderPosition
        localProfile.photos.append(objectsIn: localPhotos)
        localProfile.messages.append(objectsIn: localMessages)
        localProfile.status = (profile.status?.onlineStatus() ?? .unknown).rawValue
        localProfile.statusText = profile.lastOnlineText ?? ""
        localProfile.distanceText = profile.distanceText ?? ""
        
        return localProfile
    })
}

extension ApiProfileStatus
{
    func onlineStatus() -> OnlineStatus
    {
        switch self {
        case .unknown: return .unknown
        case .offline: return .offline
        case .away: return .away
        case .online: return .online
        }
    }
}

extension Array where Element: LMMProfile
{
    var notSeenCount: Int
    {
        var accamulator: Int = 0
        self.forEach({ profile in
            guard !profile.isInvalidated else { return }
            
            if profile.notSeen { accamulator += 1 }
        })
        
        return accamulator
    }
}

