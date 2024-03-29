//
//  ActionsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift
import RxCocoa

enum BlockReason: Int
{
    case block = 0
    case inappropriate = 10
    case stolen = 20
    case spam = 30
    case criminal = 40
    case underaged = 50
    case harrasment = 60
}

enum FeedAction
{
    case like(likeCount: Int)
    case view(viewCount: Int, viewTime: Int, actionTime: Date)
    case block(reason: BlockReason)
    case unlike
    case message(id: String, text: String)
    case viewChat(viewChatCount: Int, viewChatTime: Int, actionTime: Date)
    case readMessage(userId: String, messageId: String, actionTime: Date)
}

class ActionsManager
{
    let lastActionDate: BehaviorRelay<Date?> = BehaviorRelay<Date?>(value: nil)
    let isInternetAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    let isLikedSomeone: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)
    let lmmViewingProfiles: BehaviorRelay<Set<String>> = BehaviorRelay<Set<String>>(value: [])
    
    var notCommitedMessagesCount: Int {
        return (self.queue + self.sendingActions).filter({ $0.type == ActionType.message.rawValue }).count
    }
    
    fileprivate let db: DBService
    fileprivate let apiService: ApiService
    fileprivate let fs: FileService
    fileprivate let storage: XStorageService
    fileprivate let reachability: ReachabilityService
    fileprivate let notifications: NotificationService
    fileprivate var disposeBag: DisposeBag = DisposeBag()
    fileprivate var viewActionsMap: [String: Date] = [:]
    fileprivate var queue: [Action] = []
    fileprivate var sendingActions: [Action] = []
    fileprivate var triggerTimer: Timer?
    fileprivate var viewMap: [String: Bool] = [:]
    
    deinit
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
    }
    
    init(_ db: DBService, api: ApiService, fs: FileService, storage: XStorageService, reachability: ReachabilityService, notifications: NotificationService)
    {
        self.db = db
        self.apiService = api
        self.fs = fs
        self.storage = storage
        self.reachability = reachability
        self.notifications = notifications
        
        self.loadLastActionDate()
        self.setupDateStorage()
        self.inqueueStoredActions()
        self.setupTimerTrigger()
        self.setupBindings()
    }
    
    fileprivate func add(_ action: FeedAction, profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.add([action], profile: profile, photo: photo, source: source)
    }
    
    fileprivate func add(_ actions: [FeedAction], profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        let createdActions = actions.map({ $0.model(profile: profile, photo: photo, source: source) })

        self.db.add(createdActions).subscribe(onSuccess: { [weak self] _ in
            self?.queue.append(contentsOf: createdActions)
        }).disposed(by: self.disposeBag)
    }
    
    func addLocation(_ location: Location)
    {
        let createdAction = Action()
        createdAction.actionTime = Date()
        createdAction.type = ActionType.location.rawValue
        createdAction.setLocationData(location)
        
        self.db.add(createdAction).subscribe(onSuccess: { [weak self] _ in
            self?.queue.append(createdAction)
        }).disposed(by: self.disposeBag)
    }
    
    func markMessageRead(_ messageId: String, oppositeUserId: String)
    {
        let createdAction = Action()
        createdAction.actionTime = Date()
        createdAction.type = ActionType.readMessage.rawValue
        createdAction.setReadMessageData(oppositeUserId, messageId: messageId)
        
        self.db.add(createdAction).subscribe(onSuccess: { [weak self] _ in
            self?.queue.append(createdAction)
        }).disposed(by: self.disposeBag)
    }
    
    func commit()
    {
        guard self.apiService.isAuthorized.value else { return }
        guard !self.queue.isEmpty else { return }
        
        self.sendQueue().subscribe().disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
        self.disposeBag = DisposeBag()
        self.sendingActions.removeAll()
        self.queue.removeAll()
        self.viewMap.removeAll()
        self.viewActionsMap.removeAll()
        
        self.setupDateStorage()
        self.lastActionDate.accept(nil)
        
        self.setupTimerTrigger()
        
        UserDefaults.standard.removeObject(forKey: "isLikedSomeone")
        UserDefaults.standard.synchronize()
    }
    
    func isViewed(_ profileId: String) -> Bool
    {
        return self.viewMap[profileId] ?? false
    }
    
    func finishViewActions(for profiles: [Profile], source: SourceFeedType)
    {
        profiles.forEach { profile in
            guard !profile.isInvalidated else { return }
            
            profile.photos.forEach { photo in
                guard !photo.isInvalidated else { return }
                
                let photoId = photo.id
                
                guard let _ = self.viewActionsMap[photo.id] else { return }
                guard let actionProfile = profile.actionInstance() else { return }
                guard let actionPhoto = actionProfile.orderedPhotos().filter({ $0.id == photoId }).first else { return }
                
                self.stopViewAction(
                    actionProfile,
                    photo: actionPhoto,
                    sourceType: source
                )
            }
        }
    }
    
    func likeActionProtected(_ profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.like(likeCount: 1), profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo, sourceType: source)
        self.commit()
        
        AnalyticsManager.shared.send(.liked(source.rawValue))
        
        switch source {
        case .whoLikedMe:  AnalyticsManager.shared.send(.likedFromLikes); break
        case .messages: AnalyticsManager.shared.send(.likedFromMessages); break
            
        default: break
        }
        
        guard !self.isLikedSomeone.value else { return }
        
        // First like notifications access triggers
        if !self.notifications.isRegistered && !self.notifications.isGranted.value {
            self.notifications.register()
        }
        
        self.isLikedSomeone.accept(true)
        
    }
    
    func unlikeActionProtected(_ profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.unlike, profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo, sourceType: source)
        self.commit()
        
        AnalyticsManager.shared.send(.unliked(source.rawValue))
        
        switch source {
        case .whoLikedMe:  AnalyticsManager.shared.send(.unlikedFromLikes); break
        case .messages: AnalyticsManager.shared.send(.unlikedFromMessages); break
            
        default: break
        }
    }
    
    func blockActionProtected(_ reason: BlockReason, profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.clearProfileResources(profile)
        self.db.blockProfile(profile.id)
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.block(reason: reason), profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo, sourceType: source)
        self.commit()
    }
    
    func messageActionProtected(_ id: String, text: String, profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewChatAction(profile, photo: photo, sourceType: source)
        self.add(.message(id: id, text: text), profile: profile, photo: photo, source: source)
        self.startViewChatAction(profile, photo: photo, sourceType: source)
        self.commit()
        
        AnalyticsManager.shared.send(.messaged(source.rawValue))
        
        switch source {
        case .whoLikedMe:  AnalyticsManager.shared.send(.messagedFromLikes); break
        case .messages: AnalyticsManager.shared.send(.messagedFromMessages); break
            
        default: break
        }
    }
    
    func startViewAction(_ profile: ActionProfile, photo: ActionPhoto, sourceType: SourceFeedType)
    {
        guard viewActionsMap[photo.id] == nil else { return }
        
        self.viewActionsMap[photo.id] = Date()
        self.viewMap[profile.id] = true
        
        guard sourceType == .whoLikedMe || sourceType == .messages else { return }
        
        var profiles = self.lmmViewingProfiles.value
        profiles.insert(profile.id)
        self.lmmViewingProfiles.accept(profiles)
    }
    
    func stopViewAction(_ profile: ActionProfile, photo: ActionPhoto, sourceType: SourceFeedType)
    {
        guard !profile.isInvalidated else { return }
        guard let date = self.viewActionsMap[photo.id] else { return }
        
        self.viewActionsMap.removeValue(forKey: photo.id)
        
        let interval = Date().timeIntervalSince(date) * 1000.0
        self.add(.view(viewCount: 1, viewTime: Int(interval), actionTime: date), profile: profile, photo: photo, source: sourceType)
        
        self.db.updateSeen(profile.id, isSeen: true)

        var profiles = self.lmmViewingProfiles.value
        profiles.remove(profile.id)
        self.lmmViewingProfiles.accept(profiles)
    }
    
    func startViewChatAction(_ profile: ActionProfile, photo: ActionPhoto, sourceType: SourceFeedType)
    {
        guard viewActionsMap[photo.id] == nil else { return }
        
        self.viewActionsMap[photo.id] = Date()
        
        guard sourceType == .whoLikedMe || sourceType == .messages else { return }
        
        var profiles = self.lmmViewingProfiles.value
        profiles.insert(profile.id)
        self.lmmViewingProfiles.accept(profiles)
    }
    
    func stopViewChatAction(_ profile: ActionProfile, photo: ActionPhoto, sourceType: SourceFeedType)
    {
        guard !profile.isInvalidated else { return }
        guard let date = self.viewActionsMap[photo.id] else { return }
        
        self.viewActionsMap.removeValue(forKey: photo.id)
        
        let interval = Date().timeIntervalSince(date) * 1000.0
        self.add(FeedAction.viewChat(viewChatCount: 1, viewChatTime: Int(interval), actionTime: date), profile: profile, photo: photo, source: sourceType)

        var profiles = self.lmmViewingProfiles.value
        profiles.remove(profile.id)
        self.lmmViewingProfiles.accept(profiles)
    }
    
    func inqueueStoredActions()
    {
        self.db.actions().take(1).subscribe(onNext: { [weak self] actions in
            self?.queue.append(contentsOf: actions)
        }).disposed(by: self.disposeBag)
    }
    
    func sendQueue() -> Observable<Void>
    {
        guard self.apiService.isAuthorized.value else { return .error(createError("User not authorized", type: .hidden)) }
        guard !self.queue.isEmpty else { return .just(()) }
        
        // Delaying request if previous one still in progress
        guard self.sendingActions.isEmpty else {
            //log("Actions sendinging in progress - delaying request", level: .medium)
            
            return Observable<Void>.just(())
                .delay(RxTimeInterval.milliseconds(200), scheduler: MainScheduler.instance)
                .flatMap ({ _ -> Observable<Void> in
                    return self.sendQueue()
                })
        }
        
        let enqued = self.queue
        self.sendingActions.append(contentsOf: enqued)
        
        log("Sending events: \(self.sendingActions.count)", level: .high)
        
        let sortedActions = self.sendingActions.sorted(by: { $0.actionTime < $1.actionTime })
        let localLastActionTime = sortedActions.last?.actionTime ?? Date()
        
        return self.apiService.sendActions(sortedActions.compactMap({ $0.apiAction() }))
            .do(onError: { [weak self] _ in
                guard let `self` = self else { return }
                
                self.sendingActions.removeAll()
            })
            .flatMap({ [weak self] (date) -> Observable<Void> in
                guard let `self` = self else { return .just(()) }
                
                if abs(date.timeIntervalSince1970 - localLastActionTime.timeIntervalSince1970) > 0.001 {
                    log("ERROR: last action times not equal", level: .high)
                    SentryService.shared.send(.lastActionTimeError)
                }
                
                print("Actions sent: \(sortedActions.count)")
                self.lastActionDate.accept(date)
                self.db.delete(self.sendingActions).subscribe().disposed(by: self.disposeBag)
                self.sendingActions.removeAll()
                self.queue.removeFirst(enqued.count)
                
                return .just(())
            })
    }
    
    func checkConnectionState() -> Bool
    {
        let state = self.reachability.isInternetAvailable.value
        self.isInternetAvailable.accept(state)
        
        return state
    }
    
    func activeSendingActions() -> Observable<[String]>
    {
        return self.db.actions().map({ actions in
            return actions.filter({ $0.type == ActionType.message.rawValue })
                .compactMap({ $0.messageData()?.0 })})
    }
    
    // MARK: -
    
    fileprivate func setupBindings()
    {
        let likedState = UserDefaults.standard.bool(forKey: "isLikedSomeone")
        self.isLikedSomeone.accept(likedState)
        self.isLikedSomeone.asObservable().subscribe(onNext: { state in
            UserDefaults.standard.setValue(likedState, forKey: "isLikedSomeone")
            UserDefaults.standard.synchronize()
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTimerTrigger()
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
        
        let timer = Timer(timeInterval: 5.0, repeats: true, block: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.commit()
        })
        self.triggerTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
    
    fileprivate func clearProfileResources(_ profile: ActionProfile)
    {
        profile.photos.forEach{ photo in
            self.fs.rm(photo.filepath())
        }
    }
    
    fileprivate func setupDateStorage()
    {
        self.lastActionDate.asObservable().subscribe(onNext: { [weak self] date in
            guard let date = date else {
                self!.storage.remove("lastActionDate").subscribe().disposed(by: self!.disposeBag)
                
                return
            }
            
            self!.storage.store(date, key: "lastActionDate").subscribe().disposed(by: self!.disposeBag)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func loadLastActionDate()
    {
        self.storage.object("lastActionDate").subscribe(onSuccess: { obj in
            self.lastActionDate.accept(Date.create(obj))
        }).disposed(by: self.disposeBag)
    }
}

extension Action {
    func apiAction() -> ApiAction?
    {
        guard let type = ActionType(rawValue: self.type) else { return nil }
        
        var apiAction: ApiAction?
        
        switch type {
        case .like:
            let likeAction = ApiLikeAction()
            likeAction.likeCount = self.likeData() ?? 0
            apiAction = likeAction
            break
            
        case .view:
            let viewAction = ApiViewAction()
            let data = self.viewData()
            viewAction.viewCount = data?.viewCount ?? 1
            viewAction.viewTime = data?.viewTime ?? 1
            apiAction = viewAction
            break
            
        case .block:
            let blockAction = ApiBlockAction()
            blockAction.blockReasonNum = self.blockData() ?? 0
            apiAction = blockAction
            break
            
        case .unlike:
            apiAction = ApiUnlikeAction()
            
        case .message:
            let messageAction = ApiMessageAction()
            let messageData = self.messageData()
            messageAction.id = messageData?.id ?? ""
            messageAction.text = messageData?.text ?? ""
            apiAction = messageAction
            break
            
        case .viewChat:
            let viewChatAction = ApiViewChatAction()
            let data = self.viewChatData()
            viewChatAction.viewChatCount = data?.viewChatCount ?? 1
            viewChatAction.viewChatTime = data?.viewChatTime ?? 1
            apiAction = viewChatAction
            break
            
        case .location:
            let locationAction = ApiLocationAction()
            let data = self.locationData()
            locationAction.lon = data?.longitude ?? 0.0
            locationAction.lat = data?.latitude ?? 0.0
            apiAction = locationAction
            break
            
        case .readMessage:
            let readAction = ApiReadMessageAction()
            let data = self.readmMessageData()
            readAction.userId = data?.userId ?? ""
            readAction.messageId = data?.messageId ?? ""
            apiAction = readAction
            break
        }

        apiAction?.sourceFeed = self.sourceFeed ?? ""
        apiAction?.actionType = self.type
        apiAction?.targetPhotoId = self.photo?.id ?? ""
        apiAction?.targetUserId = self.profile?.id ?? ""
        apiAction?.actionTime = Int(self.actionTime.timeIntervalSince1970 * 1000.0)
        
        return apiAction
    }
}

extension FeedAction
{
    func model(profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType) -> Action
    {
        let createdAction = Action()
        createdAction.actionTime = Date()
        createdAction.sourceFeed = source.rawValue
        createdAction.profile = profile
        createdAction.photo = photo
        
        switch self {
        case .like(let likeCount):
            createdAction.type = ActionType.like.rawValue
            createdAction.setLikeData(likeCount)
            break
            
        case .view(let viewCount, let viewTime, let actionTime):
            createdAction.type = ActionType.view.rawValue
            createdAction.setViewData(viewCount: viewCount, viewTime: viewTime)
            createdAction.actionTime = actionTime
            break
            
        case .block(let reason):
            createdAction.type = ActionType.block.rawValue
            createdAction.setBlockData(reason.rawValue)
            break
            
        case .unlike:
            createdAction.type = ActionType.unlike.rawValue
            break
            
        case .message(let id, let text):
            createdAction.type = ActionType.message.rawValue
            createdAction.setMessageData(id, text: text)
            break
            
        case .viewChat(let viewChatCount, let viewChatTime, let actionTime):
            createdAction.type = ActionType.viewChat.rawValue
            createdAction.setViewChatData(viewChatCount: viewChatCount, viewChatTime: viewChatTime)
            createdAction.actionTime = actionTime
            break
            
        case .readMessage(let userId, let messageId, let actionTime):
            createdAction.type = ActionType.readMessage.rawValue
            createdAction.setReadMessageData(userId, messageId: messageId)
            createdAction.actionTime = actionTime
        }
        
        return createdAction
    }
}

extension BlockReason
{
    static func reportChatResons() -> [BlockReason]
    {
        return [.block, .inappropriate, .stolen, .spam, .criminal, .underaged, .harrasment]
    }
    
    static func reportResons() -> [BlockReason]
    {
        return [.inappropriate, .stolen, .spam, .underaged]
    }
    
    func title() -> String
    {
        switch self {
        case .block: return "report_profile_button_0".localized()
        case .inappropriate: return "report_profile_button_1".localized()
        case .stolen: return "report_profile_button_2".localized()
        case .spam: return "report_profile_button_3".localized()
        case .criminal: return "report_profile_button_4".localized()
        case .underaged: return "report_profile_button_5".localized()
        case .harrasment: return "report_profile_button_6".localized()
        }
    }
}
