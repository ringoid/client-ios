//
//  LMMManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 14/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

final class ChatMessageCache: NSObject
{
    let isRead: Bool
    
    init(isRead: Bool)
    {
        self.isRead = isRead
    }
}

final class ChatProfileCache: NSObject
{
    let notSeen: Bool
    let notRead: Bool
    let messagesCache: [String: ChatMessageCache]
    
    init(messagesCache: [String: ChatMessageCache], notSeen: Bool, notRead: Bool)
    {
        self.messagesCache = messagesCache
        self.notSeen = notSeen
        self.notRead = notRead
    }
    
    static func create(_ profile: LMMProfile) -> ChatProfileCache
    {
        var messagesCache: [String: ChatMessageCache] = [:]
        profile.messages.forEach({ messagesCache[$0.id] = ChatMessageCache(isRead: $0.isRead) })
        
        return ChatProfileCache(
            messagesCache: messagesCache,
            notSeen: profile.notSeen,
            notRead: !profile.isRead()
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
    let filter: FilterManager
    
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    
    var likesYou: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var messages: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var inbox: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    var sent: BehaviorRelay<[LMMProfile]> = BehaviorRelay<[LMMProfile]>(value: [])
    
    let allLikesYouProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let allMessagesProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let filteredLikesYouProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let filteredMessagesProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    let tmpAllLikesYouProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let tmpAllMessagesProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let tmpFilteredLikesYouProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    let tmpFilteredMessagesProfilesCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    let isFetching: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    
    let chatUpdateInterval: BehaviorRelay<Double> = BehaviorRelay<Double>(value: 5.0)
    
    fileprivate var likesYouCached: [LMMProfile] = []
    fileprivate var messagesCached: [LMMProfile] = []
    fileprivate var inboxCached: [LMMProfile] = []
    fileprivate var sentCached: [LMMProfile] = []
    
    fileprivate var likesYouNotificationProfiles: Set<String> = []
    fileprivate var matchesNotificationProfiles: Set<String> = []
    fileprivate var messagesNotificationProfiles: Set<String> = []
    fileprivate var processedNotificationsProfiles: Set<String> = []
    
    // Filtered content cache
    fileprivate var filteredLikesYouCache: [ApiLMMProfile]? = nil
    fileprivate var filteredMessagesCache: [ApiLMMProfile]? = nil
    fileprivate var fiteredCacheTimer: Timer? = nil
    
    // Presistent chats cache
    fileprivate var chatsCache: [String: ChatProfileCache] = [:]
    
    var contentShouldBeHidden: Bool = false
    {
        didSet {
            guard oldValue != self.contentShouldBeHidden else { return }
            
            if self.contentShouldBeHidden {
                self.likesYou.accept([])
                self.messages.accept([])
                self.inbox.accept([])
                self.sent.accept([])
            } else {
                self.likesYou.accept(self.likesYouCached)
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
    let localLmmCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    // Incoming counters
    
    fileprivate var prevNotSeenLikes: Set<String> = []
    let incomingLikesYouCount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    fileprivate var prevNotSeenMatches: Set<String> = []
    let incomingMatches: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)
    
    fileprivate var prevNotReadMessages: Set<String> = []
    let incomingMessages: BehaviorRelay<Int> = BehaviorRelay<Int>(value: 0)

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
    
    init(_ db: DBService, api: ApiService, device: DeviceService, actionsManager: ActionsManager, storage: XStorageService, notifications: NotificationService, filter: FilterManager)
    {
        self.db = db
        self.apiService = api
        self.deviceService = device
        self.actionsManager = actionsManager
        self.storage = storage
        self.notifications = notifications
        self.filter = filter
        
        self.loadPrevState()
        self.setupBindings()
    }
    
    fileprivate func refresh(_ from: SourceFeedType, isFilterEnabled: Bool) -> Observable<Void>
    {
        log("LC reloading process started", level: .high)
        self.isFetching.accept(true)
        
        (self.messages.value + self.likesYou.value).forEach({ profile in
            self.chatsCache[profile.id] = ChatProfileCache.create(profile)
        })
        
        self.updateProfilesPrevState(false)
        self.resetNotificationProfiles()
        
        // Checking cache
        if let likesYouResult = self.filteredLikesYouCache,
            let messagesResult = self.filteredMessagesCache,
            isFilterEnabled, !self.isFiltersUpdating {
            self.clearFilteredCahe()
            self.purge()
            
            let localLikesYou = createProfiles(likesYouResult, type: .likesYou, profilesCache: self.chatsCache)
            let messages = createProfiles(messagesResult, type: .messages, profilesCache: self.chatsCache)
            
            // TODO: remove after migration --------
            
            messages.forEach { remoteProfile in
                remoteProfile.notRead = remoteProfile.messages.count > 0
                
                // matches case
                if remoteProfile.messages.count == 0 {
                    remoteProfile.notSeen = true
                }
                
                self.chatsCache.forEach { localProfileId, profileCache in
                    if localProfileId == remoteProfile.id {
                        if profileCache.messagesCache.count == remoteProfile.messages.count {
                            remoteProfile.notRead = profileCache.notRead
                        } else {
                            remoteProfile.notRead = true
                        }
                        
                        // matches case
                        if remoteProfile.messages.count == 0 , profileCache.messagesCache.count == remoteProfile.messages.count {
                            remoteProfile.notSeen = profileCache.notSeen
                        }
                    }
                }
            }
            
            // ---------------------------------------
            
            self.filteredLikesYouProfilesCount.accept(self.tmpFilteredLikesYouProfilesCount.value)
            self.filteredMessagesProfilesCount.accept(self.tmpFilteredMessagesProfilesCount.value)
            self.allLikesYouProfilesCount.accept(self.tmpAllLikesYouProfilesCount.value)
            self.allMessagesProfilesCount.accept(self.tmpAllMessagesProfilesCount.value)
            
            self.isFetching.accept(false)
            return self.db.add(localLikesYou + messages).asObservable().do(onNext: { [weak self] _ in
                self?.updateProfilesPrevState(true)
            })
        }
    
        // Proceeding without cache
        
        return self.apiService.getLC(self.deviceService.photoResolution,
                              lastActionDate: self.actionsManager.lastActionDate.value,
                              source: from,
                              minAge: isFilterEnabled ? self.filter.minAge.value : nil,
                              maxAge: isFilterEnabled ? self.filter.maxAge.value : nil,
                              maxDistance: isFilterEnabled ? self.filter.maxDistance.value : nil
        ).flatMap({ [weak self] result -> Observable<Void> in
            guard let `self` = self else { return .just(()) }

            self.purge()
            
            let localLikesYou = createProfiles(result.likesYou, type: .likesYou, profilesCache: self.chatsCache)
            let messages = createProfiles(result.messages, type: .messages, profilesCache: self.chatsCache)
            
            // TODO: remove after migration --------
            messages.forEach { remoteProfile in
                remoteProfile.notRead = remoteProfile.messages.count > 0
                
                // matches case
                if remoteProfile.messages.count == 0 {
                    remoteProfile.notSeen = true
                }
                
                self.chatsCache.forEach { localProfileId, profileCache in
                    if localProfileId == remoteProfile.id {
                        if profileCache.messagesCache.count == remoteProfile.messages.count {
                            remoteProfile.notRead = profileCache.notRead
                        } else {
                            remoteProfile.notRead = true
                        }
                        
                        // matches case
                        if remoteProfile.messages.count == 0 , profileCache.messagesCache.count == remoteProfile.messages.count {
                            remoteProfile.notSeen = profileCache.notSeen
                        }
                    }
                }
            }
            
            // -----------------------------------
            
            return self.db.add(localLikesYou + messages).asObservable().do(onNext: { [weak self] _ in
                self?.updateProfilesPrevState(true)
                
                if isFilterEnabled {
                    self?.filteredLikesYouProfilesCount.accept(localLikesYou.count)
                    self?.filteredMessagesProfilesCount.accept(messages.count)
                    self?.tmpFilteredLikesYouProfilesCount.accept(localLikesYou.count)
                    self?.tmpFilteredMessagesProfilesCount.accept(messages.count)
                }
                
                self?.allLikesYouProfilesCount.accept(result.allLikesYouProfilesNum)
                self?.allMessagesProfilesCount.accept(result.allMessagesProfilesNum)
                self?.tmpAllLikesYouProfilesCount.accept(result.allLikesYouProfilesNum)
                self?.tmpAllMessagesProfilesCount.accept(result.allMessagesProfilesNum)
            })
        }).asObservable().delay(0.05, scheduler: MainScheduler.instance).do(
            onNext: { [weak self] _ in
                self?.isFetching.accept(false)
        },
            onError: { [weak self] _ in
                AnalyticsManager.shared.send(.connectionTimeout(from.rawValue))
                
                self?.isFetching.accept(false)
        })
    }
    
    func refreshInBackground(_ from: SourceFeedType)
    {
        self.refreshProtected(from, isFilterEnabled: false).subscribe().disposed(by: self.disposeBag)
    }
    
    func refreshProtected(_ from: SourceFeedType, isFilterEnabled: Bool) -> Observable<Void>
    {
        // let startDate = Date()
        self.filter.isFilteringEnabled.accept(isFilterEnabled)
        return self.actionsManager.sendQueue().flatMap ({ [weak self] _ -> Observable<Void> in
            
            return self!.refresh(from, isFilterEnabled: isFilterEnabled).asObservable()
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
    
    fileprivate var isFiltersUpdateDelayed: Bool = false
    fileprivate var isFiltersUpdating: Bool = false
    func updateFilterCounters(_ from: SourceFeedType)
    {
        guard !self.isFiltersUpdating else {
            self.isFiltersUpdateDelayed = true
            
            return
        }
        
        self.isFiltersUpdating = true
        
        self.actionsManager.sendQueue().subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.apiService.getLC(self.deviceService.photoResolution,
                                  lastActionDate: self.actionsManager.lastActionDate.value,
                                  source: from,
                                  minAge: self.filter.minAge.value,
                                  maxAge: self.filter.maxAge.value,
                                  maxDistance: self.filter.maxDistance.value
                ).do(onNext: { [weak self] _ in
                    guard let `self` = self else { return }
                    
                    self.isFiltersUpdating = false
                    
                    guard self.isFiltersUpdateDelayed else { return }
                    
                    self.isFiltersUpdateDelayed = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: {
                        self.updateFilterCounters(from)
                    })
                    }, onError: { [weak self] _ in
                        self?.isFiltersUpdating = false
                }).flatMap({ [weak self] result -> Observable<Void> in
                    // Storing data for cache
                    self?.filteredLikesYouCache = result.likesYou
                    self?.filteredMessagesCache = result.messages
                    let timer = Timer(timeInterval: 10.0, repeats: false, block: { [weak self] _ in
                        self?.clearFilteredCahe()
                    })
                    self?.fiteredCacheTimer = timer
                    RunLoop.main.add(timer, forMode: .common)
                    
                    // Updating counters
                    self?.tmpFilteredLikesYouProfilesCount.accept(result.likesYou.count)
                    self?.tmpFilteredMessagesProfilesCount.accept(result.messages.count)
                    self?.tmpAllLikesYouProfilesCount.accept(result.allLikesYouProfilesNum)
                    self?.tmpAllMessagesProfilesCount.accept(result.allMessagesProfilesNum)
                    
                    return .just(())
                }).subscribe().disposed(by: self.disposeBag)
            
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func clearFilteredCahe()
    {
        self.fiteredCacheTimer?.invalidate()
        self.fiteredCacheTimer = nil
        
        self.filteredLikesYouCache = nil
        self.filteredMessagesCache = nil
    }
    
    func topOrder(_ profileId: String, type: LMMType)
    {
        switch type {
        case .inbox: self.db.updateOrder(self.inbox.value.filter({ $0.id != profileId }), silently: false)
        case .sent: self.db.updateOrder(self.sent.value.filter({ $0.id != profileId }), silently: false)
            
            
        default: return
        }
    }
    
    func updateChat(_ profileId: String)
    {
        self.actionsManager.sendQueue().subscribe(onNext: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.apiService.getChat(profileId,
                                    resolution: self.deviceService.photoResolution,
                                    lastActionDate: self.actionsManager.lastActionDate.value).subscribe(onNext: { [weak self] chatUpdate, pullAfterInterval in
                                        
                                        self?.updateLocalProfile(profileId, update: chatUpdate)
                                        
                                        guard pullAfterInterval > 0 else { return }
                                        
                                        let interval = Double(pullAfterInterval) / 1000.0
                                        guard interval > 0.5 else { return }
                                        
                                        self?.chatUpdateInterval.accept(interval)
                                    }).disposed(by: self.disposeBag)
            
        }).disposed(by: self.disposeBag)
    }
    
    func markAsTransitioned(_ profileId: String, in feed: LMMType)
    {
        switch feed {
        case .messages: self.prevNotReadMessages.insert(profileId)
            
        default: return
        }
    }
    
    func storeFeedsState()
    {
        self.updateProfilesPrevState(false)
        
        self.storage.store(self.likesYouNotificationProfiles, key: "likesYouNotificationProfiles")
            .subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.matchesNotificationProfiles, key: "matchesNotificationProfiles")
            .subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.messagesNotificationProfiles, key: "messagesNotificationProfiles")
            .subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.processedNotificationsProfiles, key: "processedNotificationsProfiles")
            .subscribe().disposed(by: self.disposeBag)
        
        // Updating & storing chats cache
        (self.messages.value + self.likesYou.value).forEach({ profile in
            self.chatsCache[profile.id] = ChatProfileCache.create(profile)
        })
        
        if let chatsCacheData = try? NSKeyedArchiver.archivedData(withRootObject: self.chatsCache, requiringSecureCoding: false) {
            UserDefaults.standard.setValue(chatsCacheData, forKey: "chats_cache")
            UserDefaults.standard.synchronize()
        }
    }
    
    func reset()
    {
        self.allLikesYouProfilesCount.accept(0)
        self.allMessagesProfilesCount.accept(0)
        self.filteredLikesYouProfilesCount.accept(0)
        self.filteredMessagesProfilesCount.accept(0)
        
        self.tmpAllLikesYouProfilesCount.accept(0)
        self.tmpAllMessagesProfilesCount.accept(0)
        self.tmpFilteredLikesYouProfilesCount.accept(0)
        self.tmpFilteredMessagesProfilesCount.accept(0)
        
        self.storage.remove("prevNotSeenLikes").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenMatches").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("prevNotSeenHellos").subscribe().disposed(by: self.disposeBag)
        
        self.storage.remove("likesYouNotificationProfiles").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("matchesNotificationProfiles").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("messagesNotificationProfiles").subscribe().disposed(by: self.disposeBag)
        self.storage.remove("processedNotificationsProfiles").subscribe().disposed(by: self.disposeBag)
        
        UserDefaults.standard.removeObject(forKey: "filtered_likes_profiles_count")
        UserDefaults.standard.removeObject(forKey: "filtered_messages_profiles_count")
        UserDefaults.standard.removeObject(forKey: "filtered_all_likes_profiles_count")
        UserDefaults.standard.removeObject(forKey: "filtered_all_messages_profiles_count")
        
        UserDefaults.standard.removeObject(forKey: "chats_cache")
        UserDefaults.standard.removeObject(forKey: "is_first_match_recorded")
        UserDefaults.standard.synchronize()
        
        self.likesYouCached.removeAll()
        self.messagesCached.removeAll()
        self.inboxCached.removeAll()
        self.sentCached.removeAll()
        
        self.prevNotSeenLikes.removeAll()
        self.prevNotSeenMatches.removeAll()
        self.prevNotReadMessages.removeAll()
        
        self.processedNotificationsProfiles.removeAll()
        
        self.likesYou.accept([])
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
        self.messagesNotificationProfiles.remove(profileId)
    }
    
    func isMessageProfileNotRead(_ profileId: String) -> Bool
    {
        return self.messages.value.filter({ !$0.isRead() }).map({ $0.id }).contains(profileId)
    }
    
    func isBlocked(_ profileId: String) -> Bool
    {
        return self.db.isBlocked(profileId)
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        self.db.likesYou().subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            var notSeenProfiles = profiles.notSeenIDs()
            notSeenProfiles.remove(self.apiService.customerId.value)
            
            self.incomingLikesYouCount.accept(notSeenProfiles.subtracting(self.prevNotSeenLikes).count)
        }).disposed(by: self.disposeBag)
        
        self.db.messages().subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            var notSeenProfiles = profiles.filter({ $0.messages.count == 0 }).notSeenIDs()
            notSeenProfiles.remove(self.apiService.customerId.value)
            
            self.incomingMatches.accept(notSeenProfiles.subtracting(self.prevNotSeenMatches).count)
        }).disposed(by: self.disposeBag)
        
        self.db.messages().subscribe(onNext: { [weak self] profiles in
            guard let `self` = self else { return }
            
            var notReadProfiles = profiles.filter({ $0.messages.count != 0 }).notReadIDs()
            notReadProfiles.remove(self.apiService.customerId.value)
            
            if let openedProfileId = ChatViewController.openedProfileId {
                notReadProfiles.remove(openedProfileId)
            }
            
            self.incomingMessages.accept(notReadProfiles.subtracting(self.prevNotReadMessages).count)
        }).disposed(by: self.disposeBag)
        
        self.db.likesYou().subscribe(onNext: { [weak self] profiles in
            self?.likesYouCached = profiles
            
            guard self?.contentShouldBeHidden == false else { return }
            
            self?.likesYou.accept(profiles)
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

        self.likesYou.subscribe(onNext:{ [weak self] profiles in
            guard let `self` = self else { return }
            
            self.prevNotSeenLikes.formUnion(profiles.notSeenIDs())
            
            let nonSeenCount = profiles.notSeenIDs()
            .union(self.likesYouNotificationProfiles).count
            
            self.notSeenLikesYouCount.accept(nonSeenCount)
            self.updateLmmCount()
            self.updateLocalLmmCount()
        }).disposed(by: self.disposeBag)
            
        self.messages.subscribe(onNext:{ [weak self] profiles in
            guard let `self` = self else { return }
            
            let isFirstMatchRecorded = UserDefaults.standard.bool(forKey: "is_first_match_recorded")
            if  !isFirstMatchRecorded, profiles.filter({ $0.messages.count == 0 }).count > 0 {
                AnalyticsManager.shared.send(.firstMatch(SourceFeedType.messages.rawValue))
                
                UserDefaults.standard.setValue(true, forKey: "is_first_match_recorded")
                UserDefaults.standard.synchronize()
            }
            
            let notSeenMatches = profiles.filter({ $0.messages.count == 0 }).notSeenIDs()
            let notReadMessages = profiles.filter({ $0.messages.count != 0 }).notReadIDs()
            
            self.prevNotReadMessages.formUnion(notReadMessages)
            self.prevNotSeenMatches.formUnion(notSeenMatches)
            
            self.notSeenMatchesCount.accept(notSeenMatches
                .union(self.matchesNotificationProfiles).count)

            self.notSeenMessagesCount.accept(notReadMessages
                .union(self.messagesNotificationProfiles).count)
            self.updateLmmCount()
            self.updateLocalLmmCount()
        }).disposed(by: self.disposeBag)
        
        self.notifications.notificationData.subscribe(onNext: { [weak self] userInfo in
            guard let `self` = self else { return }
            guard let typeStr = userInfo["type"] as? String else { return }
            guard let remoteFeedType = RemoteFeedType(rawValue: typeStr) else { return }
            guard let profileId = userInfo["oppositeUserId"] as? String else { return }
            guard !self.isBlocked(profileId) else { return }
            
            switch remoteFeedType {
            case .likesYou:
                let isContaintedLocally = self.likesYou.value.map({ $0.id }).contains(profileId)
                if  !isContaintedLocally {
                    self.likesYouNotificationProfiles.insert(profileId)
                    let notSeenCount = self.likesYou.value.notSeenIDs().union(self.likesYouNotificationProfiles).count
                    self.notSeenLikesYouCount.accept(notSeenCount)
                    self.prevNotSeenLikes.insert(profileId)
                }

                break
                
            case .matches:
                let isContaintedLocally = self.messages.value.map({ $0.id }).contains(profileId)
                if !isContaintedLocally {
                    self.likesYouNotificationProfiles.remove(profileId)
                    self.matchesNotificationProfiles.insert(profileId)
                    
                    let notSeenCount = self.messages.value.filter({ $0.messages.count == 0 }).notSeenIDs().union(self.matchesNotificationProfiles).count
                    self.notSeenMatchesCount.accept(notSeenCount)
                    
                    let notSeenLikesCount = self.likesYou.value.notSeenIDs().union(self.likesYouNotificationProfiles).count
                    self.notSeenLikesYouCount.accept(notSeenLikesCount)
                    
                    self.prevNotSeenMatches.insert(profileId)
                }
                
                break
                                
            case .messages:
                let isContainedLocally = self.messages.value.map({ $0.id }).contains(profileId)
                let isContainedInRead = self.messages.value.filter({ $0.isRead() }).map({ $0.id }).contains(profileId)
                let isVisible = self.actionsManager.lmmViewingProfiles.value.contains(profileId)
                if isContainedLocally {
                    self.updateChat(profileId)
                    
                    if ChatViewController.openedProfileId == profileId { break }
                    if self.actionsManager.lmmViewingProfiles.value.contains(profileId) { break }
                    
                    self.prevNotReadMessages.insert(profileId)
                    
                    self.updateNotSeenCounters()
                    
                    if !isVisible && isContainedInRead {                        
                        self.messagesNotificationProfiles.insert(profileId)
                    }
                } else {
                    self.likesYouNotificationProfiles.remove(profileId)
                    self.messagesNotificationProfiles.insert(profileId)
                    
                    self.updateNotSeenCounters()
                }
                
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
            
            let nonSeenLikesYouCount = self.likesYou.value.notSeenIDs().union(self.likesYouNotificationProfiles).count
            self.notSeenLikesYouCount.accept(nonSeenLikesYouCount)
            
            let nonSeenMatchesCount = self.messages.value.filter({ $0.messages.count == 0 }).notSeenIDs().union(self.matchesNotificationProfiles).count
            self.notSeenMatchesCount.accept(nonSeenMatchesCount)
            
            let nonSeenMessagesCount = self.messages.value.filter({ $0.messages.count > 0 }).notReadIDs()
                .union(self.messagesNotificationProfiles).count
            self.notSeenMessagesCount.accept(nonSeenMessagesCount)
            
            self.updateAvailability()
        }).disposed(by: self.disposeBag)
        
        self.chatUpdateInterval.subscribe(onNext: { interval in
            UserDefaults.standard.set(interval, forKey: "chat_update_interval")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
        
        // Storing current counters value
        self.filteredLikesYouProfilesCount.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "filtered_likes_profiles_count")
        }).disposed(by: self.disposeBag)
        
        self.filteredMessagesProfilesCount.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "filtered_messages_profiles_count")
        }).disposed(by: self.disposeBag)
        
        self.allLikesYouProfilesCount.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "filtered_all_likes_profiles_count")
        }).disposed(by: self.disposeBag)
        
        self.allMessagesProfilesCount.subscribe(onNext: { value in
            UserDefaults.standard.set(value, forKey: "filtered_all_messages_profiles_count")
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func updateNotSeenCounters()
    {
        let notSeenCount = self.messages.value.filter({ $0.messages.count > 0 }).notReadIDs()
            .union(self.messagesNotificationProfiles).count
        self.notSeenMessagesCount.accept(notSeenCount)
        
        let notSeenMatchesCount = self.messages.value.filter({ $0.messages.count == 0 }).notSeenIDs().union(self.matchesNotificationProfiles).count
        self.notSeenMatchesCount.accept(notSeenMatchesCount)
        
        let notSeenLikesCount = self.likesYou.value.notSeenIDs().union(self.likesYouNotificationProfiles).count
        self.notSeenLikesYouCount.accept(notSeenLikesCount)
    }
    
    fileprivate func loadPrevState()
    {
        if let cacheData = UserDefaults.standard.data(forKey: "chats_cache"), let cache = NSKeyedUnarchiver.unarchiveObject(with: cacheData) as? [String: ChatProfileCache] {
            self.chatsCache = cache
        }
        
        self.storage.object("prevNotSeenLikes").subscribe( onSuccess: { obj in
            self.prevNotSeenLikes = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("prevNotSeenMatches").subscribe( onSuccess: { obj in
            self.prevNotSeenMatches = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("prevNotReadMessages").subscribe( onSuccess: { obj in
            self.prevNotReadMessages = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        // Notifications state
        
        self.storage.object("likesYouNotificationProfiles").subscribe(onSuccess: { obj in
            self.likesYouNotificationProfiles = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("matchesNotificationProfiles").subscribe(onSuccess: { obj in
            self.matchesNotificationProfiles = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("messagesNotificationProfiles").subscribe(onSuccess: { obj in
            self.messagesNotificationProfiles = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        self.storage.object("processedNotificationsProfiles").subscribe(onSuccess: { obj in
            self.processedNotificationsProfiles = Set<String>.create(obj) ?? []
        }).disposed(by: self.disposeBag)
        
        let interval = UserDefaults.standard.double(forKey: "chat_update_interval")
        if interval >= 0.5 {
            self.chatUpdateInterval.accept(interval)
        }
        
        // Filter counters
        let storedLikesProfilesCount = UserDefaults.standard.integer(forKey: "filtered_likes_profiles_count")
        self.filteredLikesYouProfilesCount.accept(storedLikesProfilesCount)
        
        let storedMessagesProfilesCount = UserDefaults.standard.integer(forKey: "filtered_messages_profiles_count")
        self.filteredMessagesProfilesCount.accept(storedMessagesProfilesCount)
        
        let storedAllLikesProfilesCount = UserDefaults.standard.integer(forKey: "filtered_all_likes_profiles_count")
        self.allLikesYouProfilesCount.accept(storedAllLikesProfilesCount)
        
        let storedAllMessagesProfilesCount = UserDefaults.standard.integer(forKey: "filtered_all_messages_profiles_count")
        self.allMessagesProfilesCount.accept(storedAllMessagesProfilesCount)
    }
    
    fileprivate func updateLocalProfile(_ id: String, update: ApiChatUpdate)
    {
        var localOrderPosition: Int = 0
        let updatedMessages = update.messages.map({ message -> Message in
            let localMessage = Message()
            localMessage.id = message.id
            localMessage.msgId = message.msgId
            localMessage.wasYouSender = message.wasYouSender
            localMessage.text = message.text
            localMessage.timestamp = message.timestamp
            localMessage.orderPosition = localOrderPosition
            localMessage.isRead = message.isRead
            localOrderPosition += 1
            
            return localMessage
        })
        
        self.db.lmmProfileUpdate(id,
                                 messages: updatedMessages,
                                 status: update.status?.onlineStatus() ?? .unknown,
                                 statusText: update.lastOnlineText ?? "unknown",
                                 distanceText: update.distanceText ?? "unknown",
                                 totalLikes: update.totalLikes
        )
    }
    
    fileprivate func updateProfilesPrevState(_ avoidEmptyFeeds: Bool)
    {
        let notSeenLikes = self.likesYou.value.notSeenIDs()
        if notSeenLikes.count > 0 || !avoidEmptyFeeds { self.prevNotSeenLikes.formUnion(notSeenLikes) }
        
        let notSeenMatches = self.messages.value.filter({ $0.messages.count == 0 }).notSeenIDs()
        if notSeenMatches.count > 0 || !avoidEmptyFeeds { self.prevNotSeenMatches.formUnion(notSeenMatches) }
        
        let notSeenMessages = self.messages.value.filter({ $0.messages.count != 0 }).notReadIDs()
        let seenMessages = self.messages.value.filter({ $0.messages.count != 0 }).readIDs()
        if notSeenMessages.count > 0 || !avoidEmptyFeeds {
            self.prevNotReadMessages.subtract(seenMessages)
        }
        
        self.storage.store(self.prevNotSeenLikes, key: "prevNotSeenLikes").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotSeenMatches, key: "prevNotSeenMatches").subscribe().disposed(by: self.disposeBag)
        self.storage.store(self.prevNotReadMessages, key: "prevNotReadMessages").subscribe().disposed(by: self.disposeBag)
    }
    
    fileprivate func updateLmmCount()
    {
        var lmmProfiles = Set((self.likesYou.value + self.messages.value).map({ $0.id }))
        lmmProfiles = lmmProfiles.union(self.likesYouNotificationProfiles)
        lmmProfiles = lmmProfiles.union(self.matchesNotificationProfiles)
        lmmProfiles = lmmProfiles.union(self.messagesNotificationProfiles)
        
        self.lmmCount.accept(lmmProfiles.count)
    }
    
    fileprivate func updateLocalLmmCount()
    {
        let lmmProfiles = Set((self.likesYou.value + self.messages.value).map({ $0.id }))
        self.localLmmCount.accept(lmmProfiles.count)
    }
 
    fileprivate func updateAvailability()
    {
        // Likes you
        let updatedLikesYouProfiles = self.likesYouNotificationProfiles.subtracting(self.prevLikesYouUpdatedProfiles)
        self.prevLikesYouUpdatedProfiles = self.likesYouNotificationProfiles
        
        if updatedLikesYouProfiles.count > 0 { self.likesYouUpdatesAvailable.accept(true) }
        if self.likesYouNotificationProfiles.count == 0, self.likesYouUpdatesAvailable.value { self.likesYouUpdatesAvailable.accept(false) }
        
        // Matches
        let updatedMatchesProfiles = self.matchesNotificationProfiles.subtracting(self.prevMatchesUpdatedProfiles)
        self.prevMatchesUpdatedProfiles = self.matchesNotificationProfiles
        
        if updatedMatchesProfiles.count > 0, !self.matchesUpdatesAvailable.value { self.matchesUpdatesAvailable.accept(true) }
        if self.matchesNotificationProfiles.count == 0 { self.matchesUpdatesAvailable.accept(false) }

        // Messages
        let updatedMessagesProfiles = self.messagesNotificationProfiles.subtracting(self.prevMessagesUpdatedProfiles)
        self.prevMessagesUpdatedProfiles = self.messagesNotificationProfiles
        
        if updatedMessagesProfiles.count > 0 {
            // Single profile case
            if self.messages.value.count == 1, updatedMessagesProfiles.first == self.messages.value.first?.id { return }
            
            self.messagesUpdatesAvailable.accept(true)
        }
        
        if messagesNotificationProfiles.count == 0, self.messagesUpdatesAvailable.value { self.messagesUpdatesAvailable.accept(false) }
    }
    
    fileprivate func resetNotificationProfiles()
    {
        self.likesYouNotificationProfiles.removeAll()
        self.matchesNotificationProfiles.removeAll()
        self.messagesNotificationProfiles.removeAll()
        self.prevLikesYouUpdatedProfiles.removeAll()
        self.prevMatchesUpdatedProfiles.removeAll()
        self.prevMessagesUpdatedProfiles.removeAll()
        self.notificationsProfilesCount.accept(0)
        self.lmmCount.accept(0)
    }
}

fileprivate func createProfiles(_ from: [ApiLMMProfile], type: FeedType, profilesCache: [String: ChatProfileCache]) -> [LMMProfile]
{
    var localOrderPosition: Int = 0

    return from.map({ profile -> LMMProfile in
        let profileCache = profilesCache[profile.id]
        
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
            let messageCache = profileCache?.messagesCache[message.id]
            
            let localMessage = Message()
            localMessage.id = message.id
            localMessage.msgId = message.msgId
            localMessage.wasYouSender = message.wasYouSender
            localMessage.text = message.text
            localMessage.timestamp = message.timestamp
            localMessage.orderPosition = localOrderPosition
            localMessage.isRead =  (messageCache?.isRead == true) ? true : message.isRead
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
        localProfile.gender = profile.sex
        localProfile.totalLikes = profile.totalLikes

        // Info
        localProfile.property.value = profile.info.property
        localProfile.transport.value = profile.info.transport
        localProfile.income.value = profile.info.income
        localProfile.height.value = profile.info.height
        localProfile.educationLevel.value = profile.info.educationLevel
        localProfile.hairColor.value = profile.info.hairColor
        localProfile.children.value = profile.info.children
        
        localProfile.name = profile.info.name
        localProfile.jobTitle = profile.info.jobTitle
        localProfile.company = profile.info.company
        localProfile.education = profile.info.education
        localProfile.about = profile.info.about
        localProfile.instagram = profile.info.instagram
        localProfile.tikTok = profile.info.tikTok
        localProfile.whereLive = profile.info.whereLive
        localProfile.whereFrom = profile.info.whereFrom
        localProfile.statusInfo = profile.info.statusText
        
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
    func notSeenIDs() -> Set<String>
    {
        var accamulator: Set<String> = []
        
        self.forEach({ profile in
            guard !profile.isInvalidated else { return }
            
            if profile.notSeen { accamulator.insert(profile.id) }
        })
        
        return accamulator
    }
    
    func notReadIDs() -> Set<String>
    {
        var accamulator: Set<String> = []
        
        self.forEach({ profile in
            guard !profile.isInvalidated else { return }
            
            if !profile.isRead() { accamulator.insert(profile.id) }
        })
        
        return accamulator
    }
    
    func readIDs() -> Set<String>
    {
        var accamulator: Set<String> = []
        
        self.forEach({ profile in
            guard !profile.isInvalidated else { return }
            
            if profile.isRead() { accamulator.insert(profile.id) }
        })
        
        return accamulator
    }
}

extension ChatProfileCache: NSCoding
{
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.messagesCache, forKey: "messagesCache")
        aCoder.encode(self.notSeen, forKey: "notSeen")
        aCoder.encode(self.notRead, forKey: "notRead")
    }
    
    convenience init?(coder aDecoder: NSCoder)
    {
        self.init(
            messagesCache: (aDecoder.decodeObject(forKey: "messagesCache") as? [String: ChatMessageCache]) ?? [:],
            notSeen: aDecoder.decodeBool(forKey: "notSeen"),
            notRead: aDecoder.decodeBool(forKey: "notRead")
        )
    }
}

extension ChatMessageCache: NSCoding
{
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(self.isRead, forKey: "isRead")
    }
    
    convenience init?(coder aDecoder: NSCoder)
    {
        self.init(
            isRead: aDecoder.decodeBool(forKey: "isRead"))
    }
}
