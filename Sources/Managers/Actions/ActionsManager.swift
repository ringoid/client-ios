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
    case view(viewCount: Int, viewTime: Int)
    case block(reason: BlockReason)
    case unlike
    case message(text: String)
    case openChat(openChatCount: Int, openChatTimeSec: Int)
}

class ActionsManager
{
    var lastActionDate: Date?
    
    let isInternetAvailable: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: true)
    
    fileprivate let db: DBService
    fileprivate let apiService: ApiService
    fileprivate let fs: FileService
    fileprivate let reachability: ReachabilityService
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    fileprivate var viewActionsMap: [String: Date] = [:]
    fileprivate var queue: [Action] = []
    fileprivate var sendingActions: [Action] = []
    fileprivate var triggerTimer: Timer?
    
    deinit
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
    }
    
    init(_ db: DBService, api: ApiService, fs: FileService, reachability: ReachabilityService)
    {
        self.db = db
        self.apiService = api
        self.fs = fs
        self.reachability = reachability
        
        self.inqueueStoredActions()
        self.setupTimerTrigger()
    }
    
    func add(_ action: FeedAction, profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        let createdAction = action.model(profile: profile, photo: photo, source: source)
        self.db.add([createdAction]).subscribe(onNext: { [weak self] _ in
            self?.queue.append(createdAction)
        }).disposed(by: self.disposeBag)
    }
    
    func add(_ actions: [FeedAction], profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        let createdActions = actions.map({ $0.model(profile: profile, photo: photo, source: source) })
        self.db.add(createdActions).subscribe(onNext: { [weak self] _ in
            self?.queue.append(contentsOf: createdActions)
        }).disposed(by: self.disposeBag)
    }
    
    func commit()
    {
        self.sendQueue().subscribe().disposed(by: self.disposeBag)
    }
    
    func reset()
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
        self.lastActionDate = nil
        self.queue.removeAll()
        self.setupTimerTrigger()
    }
    
    func finishViewActions(for profiles: [Profile], source: SourceFeedType)
    {
        profiles.forEach { profile in
            guard !profile.isInvalidated else { return }
            
            profile.photos.forEach { photo in
                guard !photo.isInvalidated else { return }
                guard let _ = self.viewActionsMap[photo.id] else { return }
                
                self.stopViewAction(profile.actionInstance(), photo: photo.actionInstance(), sourceType: source)
            }
        }
    }
    
    func likeActionProtected(_ profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.like(likeCount: 1), profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo)
        self.commit()
    }
    
    func unlikeActionProtected(_ profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.unlike, profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo)
        self.commit()
    }
    
    func blockActionProtected(_ reason: BlockReason, profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.clearProfileResources(profile)
        self.db.blockProfile(profile.id)
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.block(reason: reason), profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo)
        self.commit()
    }
    
    func openChatActionProtected(_ count: Int, timeSec: Int,  profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.openChat(openChatCount: count, openChatTimeSec: timeSec), profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo)
        self.commit()
    }
    
    func startViewAction(_ profile: ActionProfile, photo: ActionPhoto)
    {
        self.viewActionsMap[photo.id] = Date()
    }
    
    func stopViewAction(_ profile: ActionProfile, photo: ActionPhoto, sourceType: SourceFeedType)
    {
        guard !profile.isInvalidated else { return }
        guard let date = self.viewActionsMap[photo.id] else { return }
        
        self.viewActionsMap.removeValue(forKey: photo.id)
        
        let interval = Date().timeIntervalSince(date) * 1000.0
        self.add(FeedAction.view(viewCount: 1, viewTime: Int(interval)), profile: profile, photo: photo, source: sourceType)
    }
    
    func inqueueStoredActions()
    {
        self.db.fetchActions().take(1).subscribe(onNext: { [weak self] actions in
            self?.queue.append(contentsOf: actions)
        }).disposed(by: self.disposeBag)
    }
    
    func sendQueue() -> Observable<Void>
    {
        // Delaying request if previous one still in progress
        guard self.sendingActions.isEmpty else {
            log("Actions sendinging in progress - delaying request")
            
            return Observable<Void>.just(())
                .delay(RxTimeInterval(0.1), scheduler: MainScheduler.instance)
                .flatMap ({ _ -> Observable<Void> in
                    return self.sendQueue()
                })
        }
        
        guard !self.queue.isEmpty else { return .just(()) }
        
        let enqued = self.queue
        self.queue.removeFirst(enqued.count)
        self.sendingActions.append(contentsOf: enqued)
        
        log("Sending events: \(self.sendingActions.count)")
        
        return self.apiService.sendActions(self.sendingActions.compactMap({ $0.apiAction() }))
            .do(onNext: { [weak self] date in
                guard let `self` = self else { return }
                
                self.lastActionDate = date
                self.db.delete(self.sendingActions).subscribe().disposed(by: self.disposeBag)
                self.sendingActions.removeAll()
                }, onError: { [weak self] _ in
                    guard let `self` = self else { return }
                    
                    self.queue.insert(contentsOf: self.sendingActions, at: 0)
                    self.sendingActions.removeAll()
            }).map({ _ -> Void in return () })
    }
    
    func checkConnectionState() -> Bool
    {
        let state = self.reachability.isInternetAvailable.value
        self.isInternetAvailable.accept(state)
        
        return state
    }
    
    // MARK: -
    
    fileprivate func setupTimerTrigger()
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
        
        let timer = Timer(timeInterval: 5.0, repeats: true, block: { [weak self] _ in
            guard let `self` = self else { return }
            
            self.commit()
        })
        self.triggerTimer = timer
        RunLoop.main.add(timer, forMode: .default)
    }
    
    fileprivate func clearProfileResources(_ profile: Profile)
    {
        profile.photos.forEach{ photo in
            self.fs.rm(photo.filepath())
        }
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
            viewAction.viewCount = data?.viewCount ?? 0
            viewAction.viewTime = data?.viewTime ?? 0
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
            messageAction.text = self.messageData() ?? ""
            apiAction = messageAction
            break
            
        case .openChat:
            let openChatAction = ApiOpenChatAction()
            let data = self.openChatData()
            openChatAction.openChatCount = data?.openChatCount ?? 0
            openChatAction.openChatTimeSec = data?.openChatTimeSec ?? 0
            apiAction = openChatAction
            break
        }

        apiAction?.sourceFeed = self.sourceFeed
        apiAction?.actionType = self.type
        apiAction?.targetPhotoId = self.photo?.id ?? ""
        apiAction?.targetUserId = self.profile?.id ?? ""
        apiAction?.actionTime = Int(self.actionTime.timeIntervalSince1970)
        
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
            
        case .view(let viewCount, let viewTime):
            createdAction.type = ActionType.view.rawValue
            createdAction.setViewData(viewCount: viewCount, viewTime: viewTime)
            break
            
        case .block(let reason):
            createdAction.type = ActionType.block.rawValue
            createdAction.setBlockData(reason.rawValue)
            break
            
        case .unlike:
            createdAction.type = ActionType.unlike.rawValue
            break
            
        case .message(let text):
            createdAction.type = ActionType.message.rawValue
            createdAction.setMessageData(text)
            break
            
        case .openChat(let openChatCount, let openChatTimeSec):
            createdAction.type = ActionType.openChat.rawValue
            createdAction.setOpenChatData(openChatCount: openChatCount, openChatTimeSec: openChatTimeSec)
            break
        }
        
        return createdAction
    }
}

extension BlockReason
{
    static func reportResons() -> [BlockReason]
    {
        return [.inappropriate, .stolen, .spam, .criminal, .underaged, .harrasment]
    }
    
    func title() -> String
    {
        switch self {
        case .inappropriate: return "BLOCK_REASON_INAPPROPRIATE".localized()
        case .stolen: return "BLOCK_REASON_STOLEN".localized()
        case .spam: return "BLOCK_REASON_SPAM".localized()
        case .criminal: return "BLOCK_REASON_CRIMINAL".localized()
        case .underaged: return "BLOCK_REASON_UNDERAGED".localized()
        case .harrasment: return "BLOCK_REASON_HARRASMENT".localized()
        default: return ""
        }
    }
}
