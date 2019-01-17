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
    
    init(_ db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
        
        self.subscribeForActions()
    }
    
    func add(_ action: FeedAction, profile: Profile, photo: Photo, source: SourceFeedType)
    {
        let createdAction = action.model(profile: profile, photo: photo, source: source)
        self.db.add(createdAction).subscribe().disposed(by: self.disposeBag)
    }
    
    func add(_ actions: [FeedAction], profile: Profile, photo: Photo, source: SourceFeedType)
    {
        let createdActions = actions.map({ $0.model(profile: profile, photo: photo, source: source) })
        self.db.add(createdActions).subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func subscribeForActions()
    {
        self.db.fetchActions().subscribe(onNext: { [weak self] actions in
            guard let `self` = self else { return }
            guard !actions.isEmpty else { return }
            
            self.apiService.sendActions(actions.compactMap({ $0.apiAction() }))
                .subscribe(onNext: { [weak self] date in
                    guard let `self` = self else { return }
                    
                    self.lastActionDate = date
                    self.db.delete(actions).subscribe().disposed(by: self.disposeBag)
                }).disposed(by: self.disposeBag)
            
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
        apiAction?.targetPhotoId = self.targetPhotoId
        apiAction?.targetUserId = self.targetUserId
        apiAction?.actionTime = Int(self.actionTime.timeIntervalSince1970)
        
        return apiAction
    }
}

extension FeedAction
{
    func model(profile: Profile, photo: Photo, source: SourceFeedType) -> Action
    {
        let createdAction = Action()
        createdAction.actionTime = Date()
        createdAction.sourceFeed = source.rawValue
        createdAction.targetUserId = profile.id
        createdAction.targetPhotoId = photo.id
        
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
