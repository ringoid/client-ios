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
    let db: DBService
    let apiService: ApiService
    
    fileprivate let disposeBag: DisposeBag = DisposeBag()
    
    init(_ db: DBService, api: ApiService)
    {
        self.db = db
        self.apiService = api
        
        self.subscribeForActions()
    }
    
    func add(_ action: FeedAction, profile: Profile, photo: Photo, source: SourceFeedType)
    {
        let createdAction = Action()
        createdAction.actionTime = Date()
        createdAction.sourceFeed = source.rawValue
        createdAction.targetUserId = profile.id
        createdAction.targetPhotoId = photo.id
        
        switch action {
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
        
        self.db.add(createdAction).subscribe().disposed(by: self.disposeBag)
    }
    
    // MARK: -
    
    fileprivate func subscribeForActions()
    {
        self.db.fetchActions().subscribe(onNext: { [weak self] actions in
            guard let `self` = self else { return }
            
            print("actions: \(actions.count)")
        }).disposed(by: self.disposeBag)
    }
}
