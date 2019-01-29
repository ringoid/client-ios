//
//  ActionsManager.swift
//  ringoid
//
//  Created by Victor Sukochev on 15/01/2019.
//  Copyright © 2019 Ringoid. All rights reserved.
//

import RxSwift

enum FeedAction
{
    case like(likeCount: Int)
    case view(viewCount: Int, viewTimeSec: Int)
    case block(blockReasonNum: Int)
    case unlike
    case message(text: String)
    case openChat(openChatCount: Int, openChatTimeSec: Int)
}

class ActionsManager
{
    var lastActionDate: Date?
    
    fileprivate let db: DBService
    fileprivate let apiService: ApiService
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
    
    init(_ db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
        
        self.inqueueStoredActions()
        self.setupTimerTrigger()
    }
    
    func add(_ action: FeedAction, profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        let createdAction = action.model(profile: profile, photo: photo, source: source)
        self.db.add([createdAction]).subscribe().disposed(by: self.disposeBag)
        self.queue.append(createdAction)
    }
    
    func add(_ actions: [FeedAction], profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        let createdActions = actions.map({ $0.model(profile: profile, photo: photo, source: source) })
        self.db.add(createdActions).subscribe().disposed(by: self.disposeBag)
        self.queue.append(contentsOf: createdActions)
    }
    
    func commit()
    {
        self.sendQueue()
    }
    
    func likeActionProtected(_ profile: ActionProfile, photo: ActionPhoto, source: SourceFeedType)
    {
        self.stopViewAction(profile, photo: photo, sourceType: source)
        self.add(.like(likeCount: 1), profile: profile, photo: photo, source: source)
        self.startViewAction(profile, photo: photo)
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
        
        let interval = Date().timeIntervalSince(date)
        self.add(FeedAction.view(viewCount: 1, viewTimeSec: Int(interval)), profile: profile, photo: photo, source: sourceType)
    }
    
    // MARK: -
    
    func inqueueStoredActions()
    {
        self.db.fetchActions().subscribe(onNext: { [weak self] actions in
            self?.queue.append(contentsOf: actions)
        }).disposed(by: self.disposeBag)
    }
    
    fileprivate func sendQueue()
    {
        guard self.sendingActions.isEmpty else { return }
        guard !self.queue.isEmpty else { return }
        
        self.sendingActions.append(contentsOf: self.queue)
        self.queue.removeAll()
        
        
        self.apiService.sendActions(self.sendingActions.compactMap({ $0.apiAction() }))
            .subscribe(onNext: { [weak self] date in
                guard let `self` = self else { return }
                
                self.lastActionDate = date
                self.db.delete(self.sendingActions).subscribe().disposed(by: self.disposeBag)
                self.sendingActions.removeAll()
                }, onError: { [weak self] _ in
                    guard let `self` = self else { return }
                    
                    self.queue.insert(contentsOf: self.sendingActions, at: 0)
                    self.sendingActions.removeAll()
            }).disposed(by: self.disposeBag)
    }
    
    fileprivate func setupTimerTrigger()
    {
        self.triggerTimer?.invalidate()
        self.triggerTimer = nil
        
        let timer = Timer(timeInterval: 5.0, repeats: true, block: { [weak self] _ in
            self?.sendQueue()
        })
        self.triggerTimer = timer
        RunLoop.main.add(timer, forMode: .default)
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
            viewAction.viewTimeSec = data?.viewTimeSec ?? 0
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
            
        case .view(let viewCount, let viewTimeSec):
            createdAction.type = ActionType.view.rawValue
            createdAction.setViewData(viewCount: viewCount, viewTimeSec: viewTimeSec)
            break
            
        case .block(let blockReasonNum):
            createdAction.type = ActionType.block.rawValue
            createdAction.setBlockData(blockReasonNum)
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
